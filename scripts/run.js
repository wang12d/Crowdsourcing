require("./web3")
const contracts = require("./setup")
const events = require("./events")
const libmcs = require("./libmcs")
const Crowdsourcing = artifacts.require("Crowdsourcing");

const action = async () => {
    console.log("How to done this.")
}

module.exports = async function(callback) {
    contracts.setup().then(
        () => {
            events.subscribeLogEvent(contracts.token.contract, "TaskPublished", action)
        }
    )
    let accounts = await web3.eth.getAccounts()
    let app = await Crowdsourcing.deployed()
    // 首先模拟一个Requester和两个Workers的情况
    let requester = accounts[0]
    let a = accounts[1]
    let b = accounts[2]
    let tx = await web3.eth.sendTransaction({from: requester, to:app.address, value: web3.utils.toWei("0.8", "ether"), data:web3.utils.toHex(1)})
    let task = await app.PublishCrowdsourcingTask(web3.utils.toWei("0.8", "ether"), 2, "Image tagging", {from: requester})
    let aC = await web3.eth.sendTransaction({from: a, to: app.address, value: web3.utils.toWei("0.4"), data: web3.utils.toHex(0)})
    let aJoin = app.JoinCrowdsourcingTask(requester, {from: a})
    let bC = await web3.eth.sendTransaction({from: b, to: app.address, value: web3.utils.toWei("0.4"), data: web3.utils.toHex(0)})
    let bJoin = await app.JoinCrowdsourcingTask(requester, {from: b})
    let aR = await app.Rewarding(a, true, {from: requester})
    let bR = await app.Rewarding(b, false, {from: requester})
    callback();
}