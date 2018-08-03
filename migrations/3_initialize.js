var MemberRoles = artifacts.require("MemberRoles");
var GovBlocksMaster = artifacts.require("GovBlocksMaster");
var Master = artifacts.require("Master");
var GBTStandardToken = artifacts.require("GBTStandardToken");
var Governance = artifacts.require("Governance");
var GovernanceData = artifacts.require("GovernanceData");
var Pool = artifacts.require("Pool");
var ProposalCategory = artifacts.require("ProposalCategory");
var SimpleVoting = artifacts.require("SimpleVoting");
var EventCaller = artifacts.require("EventCaller");
var claims = artifacts.require("claims");
var claimsData = artifacts.require("claimsData");
var claimsReward = artifacts.require("claimsReward");
var master = artifacts.require("master");
var master2 = artifacts.require("masters2");
var mcr = artifacts.require("mcr");
var mcrData = artifacts.require("mcrData");
var nxmToken = artifacts.require("nxmToken");
var nxmToken2 = artifacts.require("nxmToken2");
var nxmTokenData = artifacts.require("nxmTokenData");
var pool = artifacts.require("pool");
var pool2 = artifacts.require("pool2");
var pool3 = artifacts.require("pool3");
var poolData = artifacts.require("poolData");
var quotation2 = artifacts.require("quotation2");
var quotationData = artifacts.require("quotationData");
const json = require('./../build/contracts/Master.json');
var bytecode = json['bytecode'];

module.exports = deployer => {
    let gbt;
    let ec;
    let gbm;
    let gd;
    let mr;
    let sv;
    let pc;
    let gv;
    let pl;
    let ms;
    let nms;
    let nms2;
    let nxm;
    let nxm2;
    let nxmData;
    let pl1;
    let pl2;
    let pl3;
    let pd;
    let q2;
    let qd;
    let cl;
    let cr;
    let cd;
    let mc;
    let mcd;
    deployer
    .then(() => GBTStandardToken.deployed())
    .then(function(instance){ 
        gbt = instance;
        return EventCaller.deployed();
    })
    .then(function(instance){
        ec = instance;
        return GovBlocksMaster.deployed();
    })
    .then(function(instance){
        gbm = instance;
        return gbm.govBlocksMasterInit(gbt.address, ec.address);
    })
    .then(function() {
        return gbm.setMasterByteCode(bytecode.substring(10000));
    })
    .then(function() {
        return gbm.setMasterByteCode(bytecode);
    })
    .then(function() {
        return nxmToken.deployed();
    })
    .then(function(instance) {
        nxm = instance;
        return gbm.addGovBlocksUser("0x4e455855532d4d555455414c", nxm.address, "descHash");
    })
    .then(function(){
        return GovernanceData.deployed();
    })
    .then(function(instance){ 
        gd = instance;
        return MemberRoles.deployed();
    })
    .then(function(instance){
        mr = instance;
        return ProposalCategory.deployed();
    })
    .then(function(instance){
        pc = instance;
        return pc.proposalCategoryInitiate();
    })
    .then(function(){ 
        return SimpleVoting.deployed();
    })
    .then(function(instance){ 
        sv = instance;
        return Governance.deployed();
    })
    .then(function(instance){ 
        gv = instance;
        return Pool.deployed();
    })
    .then(function(instance){
        pl = instance;
        return Master.deployed();
    })
    .then(function(instance){
        ms = instance;
        return gbm.owner();
    })
    .then(function(own){
        return ms.initMaster(own,"0x4e455855532d4d555455414c");
    })
    .then(function(){
        return ms.changeGBMAddress(GovBlocksMaster.address);
    })
    .then(function(){
        var addr = [gd.address, mr.address, pc.address, sv.address, gv.address, pl.address];
        return ms.addNewVersion(addr);
    })
    .then(function(){
        return gbm.changeDappMasterAddress("0x4e455855532d4d555455414c", Master.address);
    })
    .then(function(){
        console.log("Nexus-Mutual Dapp added!");
        return master.deployed();
    })
    .then(function(instance){
        nms = instance;
        return master2.deployed();
    })
    .then(function(instance){
        nms2 = instance;
        return nxmToken2.deployed();
    })
    .then(function(instance){
        nxm2 = instance;
        return nxmTokenData.deployed();
    })
    .then(function(instance){
        nxmData = instance;
        return mcr.deployed();
    })
    .then(function(instance){
        mc = instance;
        return mcrData.deployed();
    })
    .then(function(instance){
        mcd = instance;
        return pool.deployed();
    })
    .then(function(instance){
        pl = instance;
        return pool2.deployed();
    })
    .then(function(instance){
        pl2 = instance;
        return pool3.deployed();
    })
    .then(function(instance){
        pl3 = instance;
        return poolData.deployed();
    })
    .then(function(instance){
        pd = instance;
        return claims.deployed();
    })
    .then(function(instance){
        cl = instance;
        return claimsReward.deployed();
    })
    .then(function(instance){
        cr = instance;
        return claimsData.deployed();
    })
    .then(function(instance){
        cd = instance;
        console.log("address initialized");
    })
    .then(function(){
        console.log("Nexus-Mutual initialized !");
    });
};

