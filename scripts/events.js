const web3 = require('./web3')

const subscribedEvents = {}

const subscribeLogEvent = (contract, eventName, action) => {
    const eventJsonInterface = web3.utils._.find(
        contract._jsonInterface,
        o => o.name == eventName && o.type == 'event',
    )
    
    const subscription = web3.eth.subscribe('logs', {
        address: contract.options.address,  // 此处是智能合约的地址，等同于app.address
        topics: [eventJsonInterface.signature]
    }, (error, result) => {
        if (!error) {
            action()
        }
        else {
            console.log(result)
        }
    })
    subscribedEvents[eventName] = subscription
}

const unsubscribeEvent = (eventName) => {
    subscribedEvents[eventName].unsubscribe(function(error, success) {
        if (success) {
            console.log('Successfully unsubscribed~')
        }
    })
}

module.exports = {
    subscribeLogEvent,
    unsubscribeEvent
}