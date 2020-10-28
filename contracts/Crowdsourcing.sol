// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

// @title 移动众包-智能合约
// 主要负责处理Workers和Requesters之间的关系，它需要
// 进行：
//      1. 负责审核Workers参与任务的请求
//      2. 当Requesters创建任务时，保存Requesters所需要的押金
contract Crowdsourcing {
    // 负责保存Workers所提交的押金，每一个地址都保存一定数量的押金
    mapping(address => uint) workerCollaterals;
    // 负责保存Requesters所提交的押金，每一个地址都对应一个Requesters,
    // 上述Requesters和Workers所有的地址都需要Workers和Requesters在每个任务时
    // 自动生成
    mapping(address => uint) requesterCollaterals;
    // 对于一个任务，剩下的Workers数量
    mapping(address => uint) remainingWorkers;
    // 负责在特定条件下用来进行交互的Event，进行交易的触发
    // 假若Requester完成了任务并进行了评估，那么它就会触发一个交易来
    // 奖励Workers，同时Workers也可以通过监听该信息来判断其
    // 是否收到了相应的奖励
    event Tranfer(address indexed _from, address indexed _to, uint _val);
    event TaskPublished(address indexed _task, string indexed description);
    constructor {
    }

    function MakeCrowdsourcingTasks(address payable requester, uint collater, uint workers_needed, string description) {
        // 对任务的信息进行记录，包括保存任务的押金，记录任务需要的人数
        uint exceptedRewards = collater / workers_needed;
        description += addString("Rewards: ", uintToString(exceptedRewards));
        requesterCollaterals[requester] = collater;
        remainingWorkers[requester] = workers_needed;
        TaskPublished(_task, description);
    }
    // 辅助函数，用来进行从uint到string的转化，这一步主要是帮助Contracs进行任务的转化
    function uintToString(uint v) constant returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }
    function addString(string a, string b) internal pure returns (string) {
        return string(abi.encodePacked(a, b));
    }
}
