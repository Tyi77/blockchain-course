// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenTrade {
    // two tokens
    IERC20 public catToken;
    IERC20 public dogToken;

    // owner's info and fee
    address public owner;
    uint256 public catTokenFee;
    uint256 public dogTokenFee;

    // Trade struct
    struct Trade {
        address seller;
        IERC20 inputTokenForSale;
        uint256 inputTokenAmount;
        uint256 outputTokenAsk;
        uint256 expiry;
    }

    // Trade List
    mapping(uint256 => Trade) public tradeList;
    uint256 public tradeCount = 0;

    // Seller List
    mapping(address => uint256[]) public sellerTrades;

    // Events for setting up trades and settling trades
    event SetupTrade(
        uint256 indexed tradeId,
        address indexed seller,
        address inputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAsk,
        uint256 expiry
    );

    event SettleTrade(
        uint256 indexed tradeId,
        address indexed seller,
        address indexed buyer
    );

    constructor(address _catToken, address _dogToken) {
        owner = msg.sender;
        catToken = IERC20(_catToken);
        dogToken = IERC20(_dogToken);
    }

    // Internal
    function _removeTradeFromSeller(address seller, uint256 tradeId) internal {
        uint256[] storage ids = sellerTrades[seller];
        for (uint256 i = 0; i < ids.length; ++i) {
            if (ids[i] == tradeId) {
                ids[i] = ids[ids.length - 1];
                ids.pop();
                break;
            }
        }
    }

    // Getter
    function getSellerTrades(address seller) public view returns(uint256[] memory) {
        return sellerTrades[seller];
    }

    // Main Functions
    function setupTrade(
        address inputTokenForSale,
        uint256 inputTokenAmount,
        uint256 outputTokenAsk,
        uint256 expiry
    ) public {
        IERC20 inputToken = IERC20(inputTokenForSale);
        // validate input token and amounts
        require(
            inputToken == catToken || inputToken == dogToken,
            "The input token is not DogToken or CatToken."
        );
        require(inputTokenAmount > 0, "Amount must be greater than 0.");
        require(outputTokenAsk > 0, "Ask must be greater than 0.");
        require(expiry > block.timestamp, "Expiry must be in the future.");

        // record the trade.
        uint256 id = tradeCount;
        tradeList[id] = Trade({
            seller: msg.sender,
            inputTokenForSale: inputToken,
            inputTokenAmount: inputTokenAmount,
            outputTokenAsk: outputTokenAsk,
            expiry: expiry
        });
        tradeCount++;

        // record the seller
        sellerTrades[msg.sender].push(id);

        // lock in the input token
        uint256 fee = inputTokenAmount / 1000;
        inputToken.transferFrom(
            msg.sender,
            address(this),
            inputTokenAmount + fee
        );

        // emit the event.
        emit SetupTrade(
            id,
            msg.sender,
            inputTokenForSale,
            inputTokenAmount,
            outputTokenAsk,
            expiry
        );
    }

    function settleTrade(uint256 id) public {
        // require the user gives the right trade id.
        require(id < tradeCount, "The input id is not in the trade list.");

        Trade storage currentTrade = tradeList[id];

        // require the trade still exists.
        require(
            currentTrade.seller != address(0),
            "Trade already settled or cancelled."
        );
        // require the trade has not expired.
        require(block.timestamp < currentTrade.expiry, "Trade has expired.");

        IERC20 sellerToken = currentTrade.inputTokenForSale;
        IERC20 buyerToken = sellerToken == catToken ? dogToken : catToken;

        // settle the trade.
        buyerToken.transferFrom(
            msg.sender,
            currentTrade.seller,
            currentTrade.outputTokenAsk
        );
        sellerToken.transfer(msg.sender, currentTrade.inputTokenAmount);

        // add fee
        uint256 fee = currentTrade.inputTokenAmount / 1000;
        if (currentTrade.inputTokenForSale == catToken)
            catTokenFee += fee;
        else dogTokenFee += fee;

        // delete the trade in tradeList and sellerTrades
        address sellerAddr = currentTrade.seller;
        delete tradeList[id];
        _removeTradeFromSeller(sellerAddr, id);

        // emit the settle event
        emit SettleTrade(
            id,
            sellerAddr,
            msg.sender
        );
    }

    function withdrawFee() public {
        require(msg.sender == owner, "You are not the owner."); // require owner.
        require(catTokenFee > 0 || dogTokenFee > 0, "No fee to withdraw."); // require fee > 0.

        if (catTokenFee > 0) {
            catToken.transfer(owner, catTokenFee);
            catTokenFee = 0;
        }
        if (dogTokenFee > 0) {
            dogToken.transfer(owner, dogTokenFee);
            dogTokenFee = 0;
        }
    }

    function checkExpiry() public {
        uint256[] storage ids = sellerTrades[msg.sender];

        for (uint256 i = ids.length; i > 0; ) {
            i--;
            if (block.timestamp >= tradeList[ids[i]].expiry) {
                // return back the locked in tokens to the seller
                Trade storage currentTrade = tradeList[ids[i]];
                uint256 fee = currentTrade.inputTokenAmount / 1000;

                currentTrade.inputTokenForSale.transfer(
                    msg.sender,
                    currentTrade.inputTokenAmount + fee
                );

                // delete trade in tradeList
                delete tradeList[ids[i]];

                // delete trade in sellerTrades
                ids[i] = ids[ids.length - 1];
                ids.pop();
            }
        }
    }
}
