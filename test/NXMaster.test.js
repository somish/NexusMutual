const Claims = artifacts.require("Claims");
const ClaimsData = artifacts.require("ClaimsData");
const ClaimsReward = artifacts.require("ClaimsReward");
const NXMaster = artifacts.require("NXMaster");
const NXMaster2 = artifacts.require("NXMaster2");
const MCR = artifacts.require("MCR");
const MCRData = artifacts.require("MCRData");
const NXMToken1 = artifacts.require("NXMToken1");
const NXMToken2 = artifacts.require("NXMToken2");
const NXMTokenData = artifacts.require("NXMTokenData");
const Pool1 = artifacts.require("Pool1");
const Pool2 = artifacts.require("Pool2");
const Pool3 = artifacts.require("Pool3");
const PoolData = artifacts.require("PoolData");
const Quotation = artifacts.require("Quotation");
const QuotationData = artifacts.require("QuotationData");
let nxms;
let nxms2;
let nxmt1;
let nxmt2;
let nxmtd;
let pl1;
let pl2;
let pl3;
let pd;
let qt;
let qd;
let cl;
let cr;
let cd;
let mcr;
let mcrd;
let addr = [];

contract('NXMaster', function () {
	it('should add a new version', async function () {
		nxms = await NXMaster.deployed();
		qd = await QuotationData.new();
		nxmtd = await NXMTokenData.new("0","NXM","18","NXM");
		cd = await ClaimsData.new();
		pd = await PoolData.new();
		mcrd = await MCRData.new();
		qt = await Quotation.new();
		nxmt1 = await NXMToken1.new();
		nxmt2 = await NXMToken2.new();
		cl = await Claims.new();
		cr = await ClaimsReward.new();
		pl1 = await Pool1.new();
		pl2 = await Pool2.new();
		mcr = await MCR.new();
		nxms2 = await NXMaster2.new();
		pl3 = await Pool3.new();
		addr.push(qd.address);
		addr.push(nxmtd.address);
		addr.push(cd.address);
		addr.push(pd.address);
		addr.push(mcrd.address);
		addr.push(qt.address);
		addr.push(nxmt1.address);
		addr.push(nxmt2.address);
		addr.push(cl.address);
		addr.push(cr.address);
		addr.push(pl1.address);
		addr.push(pl2.address);
		addr.push(nxms2.address);
		addr.push(mcr.address);
		addr.push(pl3.address);
		const versionLength = await nxms.versionLength();
		await nxms.addNewVersion(addr);
		assert.equal(await nxms.versionLength(), versionLength + 1);
  });
});
