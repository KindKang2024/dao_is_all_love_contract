// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "../contracts/dependencies/mocks/AnyrandMock.sol";
// import "../contracts/BaguaDukiDaoContract.sol";
// import "@openzeppelin/contracts/interfaces/IERC20.sol";
// import "../contracts/libraries/UnstoppableDukiDaoConstants.sol";
// import "../contracts/dependencies/mocks/MyERC20Mock.sol";

// contract AnyrandMockTest is Test, ISharedStructs {
//     AnyrandMock public anyrandMock;
//     BaguaDukiDaoContract public dukiDao;
//     address public stableCoin;

//     // Test addresses
//     address public deployer = address(1);
//     address public user1 = address(2);
//     address public user2 = address(3);
//     address public automation = address(4);
//     address public community1 = address(5);
//     address public community2 = address(6);

//     // Mock ERC20 for stablecoin
//     MyERC20Mock public mockERC20;

//     function setUp() public {
//         vm.startPrank(deployer);

//         // Deploy mock ERC20 for testing
//         mockERC20 = new MyERC20Mock("Test USD", "TUSD", address(this), 0);
//         stableCoin = address(mockERC20);

//         // Deploy anyrand mock
//         anyrandMock = new AnyrandMock();

//         // Set up initial founders and maintainers
//         address[] memory creators = new address[](1);
//         creators[0] = deployer;

//         address[] memory maintainers = new address[](1);
//         maintainers[0] = user1;

//         // Configure network for BaguaDukiDaoContract
//         NetworkConfig memory config = NetworkConfig({
//             stableCoin: stableCoin,
//             anyrand: address(anyrandMock),
//             maintainers: maintainers,
//             creators: creators
//         });

//         // Deploy the DAO contract
//         dukiDao = new BaguaDukiDaoContract(config);

//         // Set automation registry
//         dukiDao.setAutomationRegistry(automation);

//         // Mint some tokens for testing
//         mockERC20.mint(deployer, 100000 * 10 ** 6); // 100,000 TUSD
//         mockERC20.mint(user1, 100000 * 10 ** 6);
//         mockERC20.mint(user2, 100000 * 10 ** 6);
//         mockERC20.mint(community1, 100000 * 10 ** 6);
//         mockERC20.mint(community2, 100000 * 10 ** 6);

//         // Prepare the DAO with some funds
//         mockERC20.approve(address(dukiDao), 50000 * 10 ** 6);
//         mockERC20.transfer(address(dukiDao), 50000 * 10 ** 6); // 50,000 TUSD

//         vm.stopPrank();
//     }

//     function testRequestAndFulfillRandomness() public {
//         // Add a community participant first
//         vm.startPrank(community1);
//         uint256 loveAmount = 100 * 10 ** 6; // 100 TUSD
//         mockERC20.approve(address(dukiDao), loveAmount);
//         dukiDao.payLoveIntoDao("Test message", "Test signature", 1, loveAmount);
//         vm.stopPrank();

//         // We'll use the automation address to trigger the evolution
//         vm.startPrank(automation);

//         // Make sure we have enough ETH for the call
//         vm.deal(automation, 1 ether);

//         // Request randomness with a callback gas limit
//         uint256 callbackGasLimit = 500000; // Increase gas limit to avoid failure
//         uint256 requestId = dukiDao.requestDaoEvolution{ value: 0.1 ether }(callbackGasLimit);

//         // Check request state
//         IAnyrand.RequestState state = anyrandMock.getRequestState(requestId);
//         assertEq(uint256(state), uint256(IAnyrand.RequestState.Pending), "Request should be pending");

//         vm.stopPrank();

//         // Now fulfill the randomness as anyone (in production this would be the Anyrand service)
//         uint256 randomValue = 12345; // Any random value for testing

//         // Ensure we have enough ETH in the contract for the evolution
//         vm.deal(address(dukiDao), 1 ether);

//         anyrandMock.fulfillRandomness(requestId, randomValue);

//         // Verify request state changed - it should be Fulfilled (2)
//         state = anyrandMock.getRequestState(requestId);
//         assertEq(uint256(state), uint256(IAnyrand.RequestState.Fulfilled), "Request should be fulfilled");

//         // Verify the DAO evolved
//         uint256 evolveRound = dukiDao.s_dao_evolve_round();
//         assertGt(evolveRound, 0, "DAO should have evolved");

//         // Check the lucky participant number
//         // The exact number will depend on the random value and participant count
//         uint256 luckyNumber = dukiDao.s_community_lucky_participant_no();
//         console.log("Lucky participant number: %s", luckyNumber);
//     }

//     function testWaitTimeEnforcement() public {
//         // Add a community participant first
//         vm.startPrank(community1);
//         uint256 loveAmount = 100 * 10 ** 6; // 100 TUSD
//         mockERC20.approve(address(dukiDao), loveAmount);
//         dukiDao.payLoveIntoDao("Test message", "Test signature", 1, loveAmount);
//         vm.stopPrank();

//         // Check initial evolve round
//         uint256 initialEvolveRound = dukiDao.s_dao_evolve_round();
//         assertEq(initialEvolveRound, 1, "Initial evolve round should be 1");

//         // Set min wait time to 1 day for testing
//         vm.startPrank(automation);
//         dukiDao.setMinWaitBetweenEvolutions(1 days);

//         // First evolution
//         vm.deal(automation, 1 ether);
//         vm.deal(address(dukiDao), 1 ether); // Ensure DAO has ETH for operations
//         uint256 requestId = dukiDao.requestDaoEvolution{ value: 0.1 ether }(500000);
//         vm.stopPrank();

//         // Fulfill the randomness
//         anyrandMock.fulfillRandomness(requestId, 12345);

//         // Verify the DAO evolved exactly once
//         uint256 evolveRound = dukiDao.s_dao_evolve_round();
//         assertEq(evolveRound, initialEvolveRound + 1, "DAO should have evolved exactly once");

//         // Try to request another evolution immediately (should fail)
//         vm.startPrank(automation);
//         vm.deal(automation, 1 ether);
//         vm.expectRevert(); // Should revert due to wait time
//         dukiDao.requestDaoEvolution{ value: 0.1 ether }(500000);
//         vm.stopPrank();

//         // Fast forward time to after wait period
//         vm.warp(block.timestamp + 1 days + 1);

//         // Add another community participant for the second evolution
//         vm.startPrank(community2);
//         loveAmount = 100 * 10 ** 6; // 100 TUSD
//         mockERC20.approve(address(dukiDao), loveAmount);
//         dukiDao.payLoveIntoDao("Test message 2", "Test signature 2", 2, loveAmount);
//         vm.stopPrank();

//         // Now it should succeed
//         vm.startPrank(automation);
//         requestId = dukiDao.requestDaoEvolution{ value: 0.1 ether }(500000);
//         vm.stopPrank();

//         // Fulfill the second randomness request
//         requestId = 2; // Second request ID
//         anyrandMock.fulfillRandomness(requestId, 67890);

//         // Verify the DAO evolved again
//         evolveRound = dukiDao.s_dao_evolve_round();
//         assertEq(evolveRound, initialEvolveRound + 2, "DAO should have evolved twice in total");
//     }

//     function testNeverCallbackAndAbort() public {
//         // Add a community participant first
//         vm.startPrank(community1);
//         uint256 loveAmount = 100 * 10 ** 6; // 100 TUSD
//         mockERC20.approve(address(dukiDao), loveAmount);
//         dukiDao.payLoveIntoDao("Test message", "Test signature", 1, loveAmount);
//         vm.stopPrank();

//         // Check initial evolve round
//         uint256 initialEvolveRound = dukiDao.s_dao_evolve_round();

//         // Request randomness with automation address
//         vm.startPrank(automation);
//         vm.deal(automation, 1 ether);
//         uint256 requestId = dukiDao.requestDaoEvolution{ value: 0.1 ether }(500000);
//         assertTrue(requestId > 0, "Request ID should be greater than 0");

//         // Verify request state is pending
//         IAnyrand.RequestState state = anyrandMock.getRequestState(requestId);
//         assertEq(uint256(state), uint256(IAnyrand.RequestState.Pending), "Request should be pending");

//         // Try to request another evolution (should fail due to pending request)
//         vm.expectRevert(abi.encodeWithSelector(IBaguaDukiDao.DaoEvolutionInProgress.selector));
//         dukiDao.requestDaoEvolution{ value: 0.1 ether }(500000);

//         // Fast forward time to simulate a long wait
//         vm.warp(block.timestamp + 7 days);

//         // Try again - should still fail because the previous request is still pending
//         vm.expectRevert(abi.encodeWithSelector(IBaguaDukiDao.DaoEvolutionInProgress.selector));
//         dukiDao.requestDaoEvolution{ value: 0.1 ether }(500000);

//         // Now abort the request - this should work because the request is no longer pending
//         dukiDao.tryAbortDaoEvolution();

//         // Try to request evolution again - should succeed now
//         uint256 newRequestId = dukiDao.requestDaoEvolution{ value: 0.1 ether }(500000);
//         assertTrue(newRequestId > requestId, "New request ID should be greater than previous");

//         vm.stopPrank();

//         // Fulfill the new request
//         anyrandMock.fulfillRandomness(newRequestId, 54321);

//         // Verify the DAO evolved
//         uint256 evolveRound = dukiDao.s_dao_evolve_round();
//         assertEq(evolveRound, initialEvolveRound + 1, "DAO should have evolved once");
//     }

//     function testUpdateConfigurableParameters() public {
//         vm.startPrank(automation);

//         // Update parameters
//         dukiDao.setMinWaitBetweenEvolutions(3 days);
//         dukiDao.setRandomnessRequestDeadline(600); // 10 minutes

//         // Verify updates
//         assertEq(dukiDao.s_minWaitBetweenEvolutions(), 3 days, "Wait time should be updated");
//         assertEq(dukiDao.s_randomnessRequestDeadline(), 600, "Deadline should be updated");

//         vm.stopPrank();

//         // Non-automation address should not be able to update
//         vm.startPrank(user1);
//         vm.expectRevert();
//         dukiDao.setMinWaitBetweenEvolutions(5 days);
//         vm.stopPrank();
//     }
// }
