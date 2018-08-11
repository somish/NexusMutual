/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.4.24;

import "./NXMToken1.sol";
import "./PoolData.sol";
import "./Quotation.sol";
import "./NXMaster.sol";
import "./Pool2.sol";
import "./MCR.sol";
import "./MCRData.sol";
import "./Iupgradable.sol";
import "./imports/openzeppelin-solidity/math/SafeMaths.sol";
import "./imports/openzeppelin-solidity/token/ERC20/StandardToken.sol";
import "./imports/openzeppelin-solidity/token/ERC20/BasicToken.sol";
import "./imports/oraclize/ethereum-api/usingOraclize.sol";
import "./imports/govblocks-protocol/Governed.sol";


contract Pool1 is usingOraclize, Iupgradable, Governed {
    using SafeMaths
    for uint;

    NXMaster ms;
    address masterAddress;
    address poolAddress;
    address mcrAddress;
    address mcrDataAddress;

    uint64 private constant DECIMAL1E18 = 1000000000000000000;

    Quotation q2;
    NXMToken1 tc1;
    PoolData pd;
    Pool2 p2;
    MCR m1;
    MCRData md;
    StandardToken stok;
    BasicToken btok;

    event Apiresult(address indexed sender, string msg, bytes32 myid);

    function Pool1() {
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
    }

    function () public payable {}

    function changeMasterAddress(address _add) {
        if (masterAddress == 0x000) {
            masterAddress = _add;
            ms = NXMaster(masterAddress);
        } else {
            ms = NXMaster(masterAddress);
            require(ms.isInternal(msg.sender) == true);
            masterAddress = _add;

        }

    }

    modifier onlyInternal {

        require(ms.isInternal(msg.sender) == true);
        _;
    }

    modifier onlyOwner {

        require(ms.isOwner(msg.sender) == true);
        _;
    }

    modifier isMemberAndcheckPause {

        require(ms.isPause() == false && ms.isMember(msg.sender) == true);
        _;
    }

    function changeDependentContractAddress() onlyInternal {
        uint currentVersion = ms.currentVersion();
        m1 = MCR(ms.versionContractAddress(currentVersion, "MCR"));
        tc1 = NXMToken1(ms.versionContractAddress(currentVersion, "TOK1"));
        pd = PoolData(ms.versionContractAddress(currentVersion, "PD"));
        md = MCRData(ms.versionContractAddress(currentVersion, "MD"));
        q2 = Quotation(ms.versionContractAddress(currentVersion, "Q2"));
        p2 = Pool2(ms.versionContractAddress(currentVersion, "P2"));
    }

    /// @dev Changes Pool1 address.
    function changePoolAddress(address _add) onlyInternal {
        poolAddress = _add;
    }

    /// @dev Calls the Oraclize Query to close a given Claim after a given period of time.
    /// @param id Claim Id to be closed
    /// @param time Time (in seconds) after which Claims assessment voting needs to be closed
    function closeClaimsOraclise(uint id, uint64 time) onlyInternal {
        bytes32 myid = oraclize_query(time, "URL", "", 3000000);
        saveApiDetails(myid, "CLA", id);
    }

    /// @dev Calls Oraclize Query to expire a given Cover after a given period of time.
    /// @param id Quote Id to be expired
    /// @param time Time (in seconds) after which the cover should be expired
    function closeCoverOraclise(uint id, uint64 time) onlyInternal {
        bytes32 myid = oraclize_query(time, "URL", strConcat("http://a1.nexusmutual.io/api/Claims/closeClaim_hash/", uint2str(id)), 1000000);
        saveApiDetails(myid, "COV", id);
    }

    /// @dev Calls the Oraclize Query to update the version of the contracts.
    function versionOraclise(uint version) onlyInternal {
        bytes32 myid = oraclize_query("URL", "http://a1.nexusmutual.io/api/MCR/setlatest/T");
        saveApiDetails(myid, "VER", version);
    }

    /// @dev Calls the Oraclize Query to initiate MCR calculation.
    /// @param time Time (in milliseconds) after which the next MCR calculation should be initiated
    function mcrOraclise(uint64 time) onlyInternal {
        bytes32 myid = oraclize_query(time, "URL", "http://a3.nexusmutual.io");
        saveApiDetails(myid, "MCR", 0);
    }

    /// @dev Sets a given investment asset as active or inactive for trading.
    function changeInvestmentAssetStatus(bytes8 curr, uint8 status) onlyAuthorizedToGovern {

        pd.changeInvestmentAssetStatus(curr, status);

    }

    // add new investment asset currency.
    function addInvestmentAssetsDetails(
        bytes8 currName,
        address curr,
        uint64 _minHoldingPercX100,
        uint64 _maxHoldingPercX100
    )
        onlyAuthorizedToGovern
    {
        pd.addInvestmentCurrency(currName);
        pd.pushInvestmentAssetsDetails(currName, curr, 1, _minHoldingPercX100, _maxHoldingPercX100, 18);
    }

    // @dev Updates investment asset min and max holding percentages.
    function updateInvestmentAssetHoldingPerc(bytes8 _curr, uint64 _minPercX100, uint64 _maxPercX100) onlyAuthorizedToGovern {

        pd.changeInvestmentAssetHoldingPerc(_curr, _minPercX100, _maxPercX100);
    }

    /// @dev Calls the Oraclize Query in case MCR calculation fails.
    /// @param time Time (in seconds) after which the next MCR calculation should be initiated
    function mcrOracliseFail(uint id, uint64 time) onlyInternal {
        bytes32 myid = oraclize_query(time, "URL", "", 1000000);
        saveApiDetails(myid, "MCRF", id);
    }

    /// @dev Oraclize call to update investment asset rates.
    function saveIADetailsOracalise(uint64 time) onlyInternal {
        bytes32 myid = oraclize_query(time, "URL", "http://a3.nexusmutual.io");
        saveApiDetails(myid, "0X", 0);
    }

    ///@dev Oraclize call to close 0x order for a given currency.
    function close0xOrders(bytes4 curr, uint id, uint time) onlyInternal {
        bytes32 myid = oraclize_query(time, "URL", "http://a3.nexusmutual.io", 300000);
        saveApiDetailsCurr(myid, "Close0x", curr, id);
    }

    ///@dev Oraclize call to close emergency pause.
    function closeEmergencyPause(uint time) onlyInternal {
        bytes32 myid = oraclize_query(time, "URL", "", 300000);
        saveApiDetails(myid, "Pause", 0);
    }

    /// @dev Handles callback of external oracle query.
    function __callback(bytes32 myid, string result) {
        require(msg.sender == oraclize_cbAddress() || ms.isOwner(msg.sender) == true);
        p2.delegateCallBack(myid);
    }

    /// @dev Enables user to purchase cover with funding in ETH.
    /// @param smartCAdd Smart Contract Address
    function makeCoverBegin(
        uint8 prodId,
        address smartCAdd,
        bytes4 coverCurr,
        uint[] coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        ) isMemberAndcheckPause payable {

        require(msg.value == coverDetails[1]);
        q2.verifyCoverDetails(prodId, msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s);

    }

    /// @dev Enables user to purchase NXM at the current token price.
    function buyTokenBegin() isMemberAndcheckPause payable {

        uint amount = msg.value;
        tc1.buyToken(amount, msg.sender);
    }

    /// @dev Sends a given amount of Ether to a given address.
    /// @param amount amount (in wei) to send.
    /// @param _add Receiver's address.
    /// @return succ True if transfer is a success, otherwise False.
    function transferEther(uint amount, address _add) onlyAuthorizedToGovern constant returns(bool succ) {
        succ = _add.send(amount);
    }

    /// @dev Sends a given Ether amount to a given address for Claims payout.
    /// @param amount amount (in wei) to send.
    /// @param _add Receiver's address.
    /// @return succ True if transfer is a success, otherwise False.
    function transferEtherForPayout(uint amount, address _add) onlyInternal constant returns(bool succ) {
        succ = _add.send(amount);
    }

    /// @dev Payable method for allocating some amount to the Pool1.
    function takeEthersOnly() payable onlyOwner {

    }

    /// @dev Gets the Balance of the Pool1 in wei.
    function getEtherPoolBalance() constant returns(uint bal) {
        bal = this.balance;
    }

    /// @dev Changes the 0x Relayer address
    function change0xFeeRecipient(address _feeRecipient) onlyAuthorizedToGovern {

        pd.change0xFeeRecipient(_feeRecipient);
    }

    ///@dev Gets Pool1 balance of a given investmentasset.
    function getBalanceofInvestmentAsset(bytes8 _curr) constant returns(uint balance) {
        address currAddress = pd.getInvestmentAssetAddress(_curr);
        btok = BasicToken(currAddress);
        return btok.balanceOf(poolAddress);
    }

    /// @dev transfers investment assets from old Pool1 to new Pool1 address.
    ///      To be automated by version control in NXMaster
    function transferIAFromPool(address _newPoolAddr) onlyOwner {

        for (uint64 i = 0; i < pd.getInvestmentCurrencyLen(); i++) {
            bytes8 currName = pd.getInvestmentCurrencyByIndex(i);
            address currAddr = pd.getInvestmentAssetAddress(currName);
            transferIAFromPool(_newPoolAddr, currAddr);
        }

    }

    ///@dev Gets Pool1 balance of a given investmentasset.
    function getBalanceOfCurrencyAsset(bytes8 _curr) constant returns(uint balance) {

        btok = BasicToken(pd.getCurrencyAssetAddress(_curr));
        return btok.balanceOf(poolAddress);
    }

    ///@dev Transfers currency from current Pool1 address to the new Pool1 address.
    function transferCurrencyFromPool(address _newPoolAddr) onlyOwner {

        for (uint64 i = 1; i < pd.getAllCurrenciesLen(); i++) {
            bytes8 currName = pd.getAllCurrenciesByIndex(i);
            address currAddr = pd.getCurrencyAssetAddress(currName);
            transferCurrencyFromPool(_newPoolAddr, currAddr);
        }
        _newPoolAddr.send(this.balance);

    }

    ///@dev Transfers investment asset from current Pool1 address to the new Pool1 address.
    function transferCurrencyFromPool(address _newPoolAddr, address currAddr) onlyInternal {
        btok = BasicToken(currAddr);
        if (btok.balanceOf(this) > 0) {
            btok.transfer(_newPoolAddr, btok.balanceOf(this));
        }
    }

    /// @dev Transfers Amount to user when claim gets accepted.
    function transferPayout(address _to, bytes8 _curr, uint _value) onlyInternal {
        btok = BasicToken(pd.getCurrencyAssetAddress(_curr));
        if (btok.balanceOf(this) > _value)
            btok.transfer(_to, _value);
    }

    /// @dev Transfers specific currency asset from current Pool1 address to the new Pool1 address.
    function transferFromPool(address _to, address _currAddr, uint _amount) onlyInternal {
        btok = BasicToken(_currAddr);
        if (btok.balanceOf(this) >= _amount)
            btok.transfer(_to, _amount);
    }

    /// @dev Transfers amount to Pool1 from 0x order maker.
    function transferToPool(address currAddr, uint amount) onlyInternal returns(bool success) {
        stok = StandardToken(currAddr);
        success = stok.transferFrom(pd.get0xMakerAddress(), poolAddress, amount);
    }

    ///@dev Gets 0x wrapped ether Pool1 balance.
    function getWETHPoolBalance() constant returns(uint wETH) {
        btok = BasicToken(pd.getWETHAddress());
        return btok.balanceOf(poolAddress);
    }

    ///@dev Gets 0x order details by hash.
    function getOrderDetailsByHash(bytes16 orderType, bytes8 makerCurr, bytes8 takerCurr)
    constant
    returns(
        address makerCurrAddr,
        address takerCurrAddr,
        uint salt,
        address feeRecipient,
        address takerAddress,
        uint makerFee,
        uint takerFee
        ) {

        if (orderType == "ELT") {
            if (makerCurr == "ETH")
                makerCurrAddr = pd.getWETHAddress();
            else
                makerCurrAddr = pd.getCurrencyAssetAddress(makerCurr);
            takerCurrAddr = pd.getInvestmentAssetAddress(takerCurr);
        } else if (orderType == "ILT") {
            makerCurrAddr = pd.getInvestmentAssetAddress(makerCurr);
            if (takerCurr == "ETH")
                takerCurrAddr = pd.getWETHAddress();
            else
                takerCurrAddr = pd.getCurrencyAssetAddress(takerCurr);
        } else if (orderType == "RBT") {
            makerCurrAddr = pd.getInvestmentAssetAddress(makerCurr);
            takerCurrAddr = pd.getWETHAddress();
        }
        salt = pd.getOrderSalt();
        feeRecipient = pd.get0xFeeRecipient();
        takerAddress = pd.get0xTakerAddress();
        makerFee = pd.get0xMakerFee();
        takerFee = pd.get0xTakerFee();
    }

    /// @dev Enables user to purchase cover via currency asset eg DAI
    function makeCoverUsingCA(
        uint8 prodId,
        address smartCAdd,
        bytes4 coverCurr,
        uint[] coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        ) isMemberAndcheckPause {
        stok = StandardToken(pd.getCurrencyAssetAddress(coverCurr));
        stok.transferFrom(msg.sender, this, coverDetails[1]);
        q2.verifyCoverDetails(prodId, msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s);
    }

    /// @dev Enables user to sell NXM tokens
    function sellNXMTokens(uint sellTokens) isMemberAndcheckPause {
        require(tc1.balanceOf(msg.sender) >= sellTokens); // Check if the sender has enough
        require(tc1.tokensLocked(msg.sender, "MV", now) == 0);
        uint sellingPrice = SafeMaths.div(SafeMaths.mul(SafeMaths.mul(m1.calculateTokenPrice("ETH"), sellTokens), 975), 1000);
        uint sellTokensx10e18 = SafeMaths.mul(sellTokens, DECIMAL1E18);
        require(sellTokensx10e18 <= getMaxSellTokens());
        tc1.burnToken(msg.sender, "ForTokenSell", 0, sellTokensx10e18);
        bool succ = msg.sender.send(sellingPrice);
        require(succ != false);
    }

    /// @dev Gets max numbers of tokens that can be sold at the moment.
    function getMaxSellTokens() constant returns(uint maxTokens) {
        uint maxTokensAccPoolBal = SafeMaths.sub(getEtherPoolBalance(), SafeMaths.mul(
            SafeMaths.div(SafeMaths.mul(50, pd.getCurrencyAssetBaseMin("ETH")), 100), DECIMAL1E18));
        maxTokensAccPoolBal = SafeMaths.mul(SafeMaths.div(maxTokensAccPoolBal, m1.calculateTokenPrice("ETH")), DECIMAL1E18);
        maxTokens = SafeMaths.mul(SafeMaths.div(SafeMaths.mul(SafeMaths.sub(md.getLastMCRPerc(), 10000), 2000), 10000), DECIMAL1E18);
        if (maxTokens > maxTokensAccPoolBal)
            maxTokens = maxTokensAccPoolBal;
    }

    /// @dev Save the details of the Oraclize API.
    /// @param myid Id return by the oraclize query.
    /// @param _typeof type of the query for which oraclize call is made.
    /// @param id ID of the proposal, quote, cover etc. for which oraclize call is made.
    function saveApiDetails(bytes32 myid, bytes8 _typeof, uint id) internal {
        pd.saveApiDetails(myid, _typeof, id);
        pd.addInAllApiCall(myid);

    }

    /// @dev Save the details of the Oraclize API.
    /// @param myid Id return by the oraclize query.
    /// @param _typeof type of the query for which oraclize call is made.
    /// @param curr currencyfor which api call has been made.
    /// @param id ID of the proposal, quote, cover etc. for which oraclize call is made.
    function saveApiDetailsCurr(bytes32 myid, bytes8 _typeof, bytes4 curr, uint id) internal {
        pd.saveApiDetailsCurr(myid, _typeof, curr, id);
        pd.addInAllApiCall(myid);
    }

    ///@dev Transfers investment asset from current Pool1 address to the new Pool1 address.
    ///      To be automated by version control in NXMaster
    function transferIAFromPool(address _newPoolAddr, address currAddr) internal {
        btok = BasicToken(currAddr);
        if (btok.balanceOf(this) > 0) {
            btok.transfer(_newPoolAddr, btok.balanceOf(this));
        }
    }
}
