const web3 = require('./web3')
const csInterface = require('../build/contracts/Crowdsourcing.json')

const token = {}

const setupToken = async (netWorkId) => {
    const appAdress = csInterface.networks[netWorkId].address
    token.contract = new web3.eth.Contract(
        csInterface.abi, appAdress
    )
}

const setup = async () => {
    const networkId = await web3.eth.net.getId()
    await setupToken(networkId.toString())
}

module.exports = {
    token,
    setup
}
