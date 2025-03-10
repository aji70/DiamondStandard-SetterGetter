// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/additionalFacets/SetterGetterFacet.sol";
import "../contracts/facets/additionalFacets/SetEmail.sol";

import "../contracts/libraries/LibAppStorage.sol";
import "forge-std/Test.sol";
import "../contracts/Diamond.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    SetterGetterFacet setterF;
    SetEmail setE;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        setterF = new SetterGetterFacet();
        setE = new SetEmail();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](4);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(setterF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("SetterGetterFacet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(setE),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("SetEmail")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function testLayoutfacet2() public {
        SetterGetterFacet l = SetterGetterFacet(address(diamond));

        l.ChangeNameAndNo(67, "John");

        // check outputs
        SetEmail li = SetEmail(address(diamond));

        li.setEmail("aji@gmail.com");
        LibAppStorage.Layout memory laa = li.getLayout1();
        assertEq(laa.name, "John");
        assertEq(laa.currentNo, 67);
        assertEq(laa.email, "aji@gmail.com");
    }

    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
