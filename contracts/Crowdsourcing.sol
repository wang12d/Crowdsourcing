// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// @title 移动众包-智能合约
// 主要负责处理Workers和Requesters之间的关系，它需要
// 进行：
//      1. 负责审核Workers参与任务的请求
//      2. 当Requesters创建任务时，保存Requesters所需要的押金
contract Crowdsourcing is ERC20 {
    // 负责保存Workers所提交的押金，每一个地址都保存一定数量的押金
    mapping(address => uint) workerCollaterals;
    // 负责保存Requesters所提交的押金，每一个地址都对应一个Requesters,
    // 上述Requesters和Workers所有的地址都需要Workers和Requesters
    // 在每个任务时自动生成
    mapping(address => uint) requesterCollaterals;
    // 对于一个任务，剩下的Workers数量
    mapping(address => uint) remainingWorkers;
    // 对于每个任务所需要的押金
    mapping(address => uint) taskCollaterals;
    // 计算每个Worker应该获得的奖励
    mapping(address => uint) workerAwards;
    // 确保每个任务都有其对应的workers，在进行奖励分发的时候使用
    mapping(address => mapping(address => bool)) workersOfTask;
    // 每个worker是否进行了数据上传
    mapping(address => mapping(address => bool)) dataSubmitted;
    // 
    // 负责在特定条件下用来进行交互的Event，进行交易的触发
    // 假若Requester完成了任务并进行了评估，那么它就会触发一个交易来
    // 奖励Workers，同时Workers也可以通过监听该信息来判断其
    // 是否收到了相应的奖励
    event TaskPublished(address indexed _task, string description);
    event Tranfer(address indexed _from, address indexed _to, uint _val);
    event DataSubmitted(address indexed _from, bytes data);
    /**
     * 为了保证该Smart Contract能够接受来自其他用户的押金
     * 需要实现Fallback Function. 
     * Requester需要将押金从传递到智能合约的地址
     * 后期为了进行权限控制，需要判断消息发送者是否真的为Requesters
     * Workers需要将押金从传递到智能合约的地址 
     * 后期为了进行权限控制，需要判断消息发送者是否真的为Workers
     */
    constructor() public ERC20("TaskSubmissionTicket", "TST") {
    }
    // 根据Solidity 0.6.2的描述进行修改 https://docs.soliditylang.org/en/v0.6.0/contracts.html#receive-ether-function.
    fallback() external payable {
        bytes memory requester = hex"01";
        bytes memory worker = hex"00";
        require(keccak256(abi.encodePacked(msg.data)) == keccak256(abi.encodePacked(requester)) || 
            keccak256(abi.encodePacked(msg.data)) == keccak256(abi.encodePacked(worker)), 
            "You should either be worker or requester");
        if (keccak256(abi.encodePacked(msg.data)) == keccak256(abi.encodePacked(requester))) {
            requesterCollaterals[msg.sender] += msg.value;
        }
        else {
            workerCollaterals[msg.sender] += msg.value;
        }
    }
    // 
    // 创建一个新的众包任务，同时该函数会发出一个新的Event表示任务已经创建成功
    // Workers可以通过订阅这个Event来接收到最新的Tasks的信息，从而自己决定要不要
    // 参加该众包任务
    function PublishCrowdsourcingTask(address payable requester, uint collater, uint workers_needed, string memory description) public {
        // 对任务的信息进行记录，包括保存任务的押金，记录任务需要的人数
        require (requesterCollaterals[requester] >= collater, "Not enough amount to pay the collaterals");
        uint exceptedRewards = collater / workers_needed;
        description = addString(description, addString("\nRewards: ", uintToString(exceptedRewards)));
        // 假若Requester已经提交了押金，那么其在智能合约里面存储的剩余
        // 押金应该是大于或等于collater的
        requesterCollaterals[requester] -= collater;
        // 目前这个状态也是处理对于任务奖励的金额
        // 但是可能会有一个潜在的BUG，那就是在任务完成之后并没有
        // 将其内容全部清零
        taskCollaterals[requester] = exceptedRewards;
        remainingWorkers[requester] = workers_needed;
        emit TaskPublished(requester, description);
    }
    // 给定一个地址，查看其所需要的Workers数量是否已满
    function RemainingWorkers(address task) public view returns (uint rem) {
        rem = remainingWorkers[task];
    }
    /** 
    * Workers参与任务
    * 用户想要参加某一个众包任务，它需要缴纳一定的押金，一部分是作为激励
    * 同时也是为了防止用户进行女巫攻击
    **/
    function JoinCrowdsourcingTask(address payable worker, address payable task) public {
        uint remWorkers = remainingWorkers[task];
        require (remWorkers > 0, "The task no longer needs more worker");
        require (workerCollaterals[worker] >= taskCollaterals[task], "Not enough amount to pay the collaterals");
        workersOfTask[task][worker] = true;
        workerAwards[worker] += taskCollaterals[task];
        workerCollaterals[worker] -= taskCollaterals[task];
        // 此时任务算是被workers接受了
        remainingWorkers[task]--;
    }
    /**
    * Workers进行任务上传
    * 它应该上传的是一个加密的数据包，或者当数据直接在区块链上面
    * 进行传递时不划算了，那么则应该上传相应对应数据块的索引，这样
    * 相应Requester就能够找到并对其进行访问
    */
    function SubmitData(address payable task, bytes memory data) public {
        // For each requester, the worker can only upload
        // the encrypted data it collects at most once to avoid
        // a user uses the same address to upload multiple data
        require(workersOfTask[task][msg.sender] == false, "You already submitted your data");
        workersOfTask[task][msg.sender] = true;
        emit DataSubmitted(task, data); // Requester by subscription to track the process of the current task
    }
    /**
    * 进行任务奖励
    * 按照我们设计的协议，任务应该是由Workers直接提交到Requesters的，
    * 但是目前在这里作为测试用例，在智能合约上面实现该操作
    */
    function Rewarding(address payable worker, bool isok) public {
        // 只有Requester才能调用此信息
        require(workersOfTask[msg.sender][worker] == true, "Only requester can call this to workers who participants its task");
        if (isok) {
            worker.transfer(workerAwards[worker]+taskCollaterals[msg.sender]);
        }
        else {
            worker.transfer(workerAwards[worker]);
            msg.sender.transfer(taskCollaterals[msg.sender]);
        }
        // 奖励已经发出，现在清除其状态
        workersOfTask[msg.sender][worker] = false;
        workerAwards[worker] = 0;
    }
    // 辅助函数，用来进行从uint到string的转化，这一步主要是帮助Contracs进行任务的转化
    function uintToString(uint v) internal pure returns (string memory str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }
    function addString(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    // 将字符串转化为固定长度的Bytes32，这样客户端可以很方便的将Event重新转化为字符串再进行描述
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
}
