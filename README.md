## ERC7527

[ERC7527](https://github.com/lanyinzly/ERCs/blob/lanyinzly-patch-1/ERCS/erc-7527.md) 

这是一个包含 `EIP7527` 标准实现的仓库，核心合约包含 `ERC7527Agency`/ `ERC7527App` / `ERC7527Factory` 三部分，其接口可以在 `src/interfaces` 内找到。

不同合约的主要功能如下:

- `ERC7527Agency` 存储用户同质化资产，并调用 `ERC7527App` 的铸造接口为用户铸造非同质化资产，核心函数为 `wrap` 和 `unwrap`
- `ERC7527App` 继承了 NFT 标准实现，主要提供了 NFT 的一系列功能
- `ERC7527Factory` 作为工厂函数，用于 `ERC7527Agency` 和 `ERC7527App` 的快速部署

> `ERC7527Factory` 使用了 [ClonesWithImmutableArgs](https://github.com/wighawag/clones-with-immutable-args/blob/master/src/ClonesWithImmutableArgs.sol) 方法，此方法类似 EIP1167 ，但是在 EIP1167 基础上增加了为 `clone` 合约提供初始化参数的能力

本示例项目使用了以下函数作为数学函数:

$f(x) = k + \frac{x \times k}{100}$


此处的 `k` 在代码中表现为 `_asset.premium` 参数，而此处的 `x` 指 `swap` 的调用次数，简单来说，该合约定义了一种资产，随着资产铸造的次数增加，资产的价格也会随之上升。

### 合约部署

理解一个项目最简单的方法就是完整部署一次项目合约，我使用了以下 solidity 代码进行了项目的部署:

```solidity
contract ERC7527Test is Test {
    ERC7527Agency public agency;
    ERC7527App public app;

    ERC7527Factory public factory;

    address public appDeployAddress;
    address public agencyDeployAddress;

    function setUp() public {
        agency = new ERC7527Agency();
        app = new ERC7527App();

        factory = new ERC7527Factory();

        Asset memory asset = Asset({
            currency: address(0),
            premium: 0.1 ether,
            feeRecipient: address(1),
            mintFeePercent: uint16(10),
            burnFeePercent: uint16(10)
        });

        AgencySettings memory agencySettings = AgencySettings({
            implementation: payable(address(agency)),
            asset: asset,
            immutableData: bytes(""),
            initData: bytes("")
        });

        AppSettings memory appSettings =
            AppSettings({implementation: address(app), immutableData: bytes(""), initData: bytes("")});

        (appDeployAddress, agencyDeployAddress) = factory.deployWrap(agencySettings, appSettings, bytes(""));
    }
}
```

> 具体的代码请参考 [ERC7527.t.sol](test/ERC7527.t.sol) 文件

我们使用了 `ERC7527Factory` 工厂合约的 `deployWrap` 函数进行了项目部署，该合约需要以下三个参数:

- `AgencySettings` 用于定义 `agency` 合约的参数，主要定义了以下参数:
    - `implementation` 此 `agency` 合约的实现地址
    - `asset` 此 `agency` 资产配置结构体，会在后文详细介绍
    - `immutableData` 合约内包含的其他不可变数据，比如更加多样的模型参数
    - `initData` 此 `agency` 合约的初始化调用参数
- `AppSettings` 用于定义 `app` 合约的参数
    - `implementation` 此 `app` 合约的实现地址
    - `immutableData` 同上
    - `initData` 同上

接下来，我们详细介绍 `AgencySettings` 内使用的 `Asset` 结构体，该结构体用于定义 `agency` 合约的资产:

- `currency` 此 `agency` 合约的所接受的 **币种**，如为 `address(0)` 则表示使用 ETH
- `premium` 此 `agency` 合约的 **权利金**，具体来说是上文的 `k`
- `feeRecipient` 此 `agency` 合约的 **手续费收款人**，此处设置为为 `address(1)`
- `mintFeePercent` 此 `agency` 合约的 **铸造手续费万分比**，此处设置为 `10`
- `burnFeePercent` 此 `agency` 合约的 **销毁手续费万分比**，此处设置为 `10`

在介绍完上述参数后，我们可以深入了解 `ERC7527Factory` 合约中的内容，该合约创建 `ERC7527Agency` 和 `ERC7527App` 合约时使用了 `ClonesWithImmutableArgs` 的方法，该方法是建立在 EIP1167 的基础上，如果您不了解 EIP1167 则可以参考本 EIP 核心贡献者所写的 [EVM底层探索:字节码级分析最小化代理标准EIP1167](https://blog.wssh.trade/posts/deep-in-eip1167/) 一文。

`ClonesWithImmutableArgs` 的合约代码可以参考 [wighawag/clones-with-immutable-args](https://github.com/wighawag/clones-with-immutable-args/blob/master/src/ClonesWithImmutableArgs.sol) 仓库，其大部分核心代码都来自 EIP1167，但该合约在 EIP1167 的逻辑最后增加了 `APPENDED DATA` 部分，这样我们可以在逻辑内使用 `calldataload` 进行参数的提取，比如 `ERC7527Agency` 合约中的 `getStrategy` 函数，其代码如下:

```solidity
function getStrategy() public pure override returns (address app, Asset memory asset, bytes memory attributeData) {
    uint256 offset = _getImmutableArgsOffset();
    address currency;
    uint256 premium;
    address payable awardFeeRecipient;
    uint16 mintFeePercent;
    uint16 burnFeePercent;
    assembly {
        app := shr(0x60, calldataload(add(offset, 0)))
        currency := shr(0x60, calldataload(add(offset, 20)))
        premium := calldataload(add(offset, 40))
        awardFeeRecipient := shr(0x60, calldataload(add(offset, 72)))
        mintFeePercent := shr(0xf0, calldataload(add(offset, 92)))
        burnFeePercent := shr(0xf0, calldataload(add(offset, 94)))
    }
    asset = Asset(currency, premium, awardFeeRecipient, mintFeePercent, burnFeePercent);
    attributeData = "";
}
```

当然，对附加参数的读取实际上与 `APPENDED DATA` 部分写入的数据格式有关，在 `ERC7527Factory` 中，我们可以找到如下代码:

```solidity
{
    agencyInstance = address(agencySettings.implementation).clone(
        abi.encodePacked(
            appInstance,
            agencySettings.asset.currency,
            agencySettings.asset.premium,
            agencySettings.asset.feeRecipient,
            agencySettings.asset.mintFeePercent,
            agencySettings.asset.burnFeePercent,
            agencySettings.immutableData
        )
    );
}
```

我们将所有附加参数使用 `abi.encodePacked` 的方法写入了代理合约，所以上文 `getStrategy` 的 `yul` 代码就是在进行 `abi.encodePacked` 的反向操作。

### 包装

接下来，我们主要分析 `warp` 功能，此函数用于用户输入资产并将其转化为指定 tokenId 的 NFT 

`warp` 的定义如下:

```solidity
function wrap(address to, bytes calldata data) external payable override returns (uint256) {}
```

此处的 `to` 指接受 NFT 的用户地址，而 `data` 实际上指用户铸造的 NFT 的 tokenId。

`warp` 函数的具体实现如下:

```solidity
function wrap(address to, bytes calldata data) external payable override returns (uint256) {
    (address _app, Asset memory _asset,) = getStrategy();
    uint256 _sold = IERC721Enumerable(_app).totalSupply();
    (uint256 swap, uint256 mintFee) = getWrapOracle(abi.encode(_sold));
    require(msg.value >= swap + mintFee, "ERC7527Agency: insufficient funds");
    _transfer(address(0), _asset.feeRecipient, mintFee);
    if (msg.value > swap + mintFee) {
        _transfer(address(0), payable(msg.sender), msg.value - swap - mintFee);
    }
    uint256 id_ = IERC7527App(_app).mint(to, data);
    emit Wrap(to, id_, swap, mintFee);
    return id_;
}
```

此处我们调用 `getWrapOracle` (即上文展示的数学函数) 获得当前可以兑换的额度与交换的手续费，然后使用 `_transfer` 函数将多余的资产退还到用户钱包，最后为用户铸造 NFT 完成全部流程。注意，此处 `getWrapOracle` 函数接受的输入值为当前 NFT 的 `totalSupply` ，且该数据在给用户发行 NFT 前就已给定

我们在 `test/ERC7527.t.sol` 文件内对此函数进行了演示测试:

```solidity
function testWarp() public {
    vm.deal(address(this), 1 ether);
    IERC7527Agency(payable(agencyDeployAddress)).wrap{value: 0.5 ether}(address(this), abi.encode(uint256(1)));

    assertEq(IERC721Enumerable(appDeployAddress).totalSupply(), uint256(1));
    assertEq(IERC721Enumerable(appDeployAddress).ownerOf(1), address(this));
    assertEq(agencyDeployAddress.balance, uint256(0.1 ether));
    assertEq(address(1).balance, uint256(0.0001 ether));
    assertEq(address(this).balance, uint256(1 ether - 0.1001 ether));
}
```

此处调用 `wrap` 函数进行包装操作，同时设置该笔交易的 ETH 数量为 `0.5 ether`，根据我们的设置，此次交易将存入 `agency` 账户 0.1 ether，且给予手续费收入账户 0.0001 ether(即交易金额的 0.01%)。

$$
\begin{split}
f(x) &= k + \frac{x \times k}{100} \\
&= {0.1 ether} + \frac{0 \times {0.1 ether}}{100} \\
&= {0.1 ether} \\
\end{split}
$$

> 您可以在 `src/ERC7527.sol` 合约找到实现上述计算的 `getWrapOracle` 函数

### 解包装

当用户需要解除包装时，需要调用 `unwarp` 函数，该函数实现如下:

```solidity
function unwrap(address to, uint256 tokenId, bytes calldata data) external payable override {
    (address _app, Asset memory _asset,) = getStrategy();
    require(_isApprovedOrOwner(_app, msg.sender, tokenId), "LnModule: not owner");
    IERC7527App(_app).burn(tokenId, data);
    uint256 _sold = IERC721Enumerable(_app).totalSupply();
    (uint256 swap, uint256 burnFee) = getUnwrapOracle(abi.encode(_sold));
    _transfer(address(0), payable(to), swap - burnFee);
    _transfer(address(0), _asset.feeRecipient, burnFee);
    emit Unwrap(to, tokenId, swap, burnFee);
}
```

该函数首先确认进行解质押操作的用户为 NFT 的所有权(包含直接持有 NFT 或者被 NFT 持有者 `approve` 两种情况)，然后直接 `burn` 用户的 NFT ，并使用 `getUnwrapOracle` 函数计算用户可以获得的 ETH 数量和解包装手续费，最后进行资产转移。

此处读者需要注意，我们在 `burn` 后读取的 `totalSupply` ，这样可以与包装操作对称避免 `agency` 资产出现超发。一般来说，在处理 ETH 资产时， `warp` 和 `unwarp` 应当对称，否则就会出现 `agency` 资产在所有用户都解除质押后出现资产不足或者仍剩余部分资产的情况。

我们给出此部分的测试:

```solidity
function testUnwarp() public {
    vm.deal(address(this), 1 ether);
    IERC7527Agency(payable(agencyDeployAddress)).wrap{value: 0.5 ether}(address(this), abi.encode(uint256(1)));
    IERC7527Agency(payable(agencyDeployAddress)).unwrap(address(this), 1, bytes(""));

    assertEq(IERC721Enumerable(appDeployAddress).totalSupply(), uint256(0));
    assertEq(address(this).balance, uint256(0.9998 ether));
    assertEq(address(1).balance, uint256(0.0002 ether));
}
```

### 本地部署

我们使用 `foundry` 框架中的 `anvil` 启动本地测试网，使用以下命令进行 `Implementation` 的部署:

```bash
forge script script/ERC7527.s.sol:ImplementationScript --broadcast --private-key $LOCAL_PRIVATE --rpc-url http://127.0.0.1:8545
```
上述命令执行完成后，我们可以获得如下输出:

```bash
== Return ==
agency: contract ERC7527Agency 0x5FbDB2315678afecb367f032d93F642f64180aa3
app: contract ERC7527App 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
factory: contract IERC7527Factory 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

用户可以根据自身合约地址返回值对 `AgenctWithAppScript` 中的 `setUp()` 函数进行调整

使用以下命令调用 `ERC7527Factory` 工厂合约的 `deployWrap` 进行第一次部署：

```bash
forge script script/ERC7527.s.sol:AgenctWithAppScript --broadcast --private-key $LOCAL_PRIVATE --rpc-url http://127.0.0.1:8545
```

读者可以在终端内获得以下输出:

```solidity
== Return ==
cloneAgency: address 0xE451980132E65465d0a498c53f0b5227326Dd73F
cloneApp: address 0x75537828f2ce51be7289709686A69CbFDbB714F1
```

接下来，读者可以进行一系列其他操作。

比如包装资产，命令如下:

```bash
cast send $AGENCY "wrap(address, bytes)(uint256)" $LOCAL_ACCOUNT "0x0000000000000000000000000000000000000000000000000000000000000001" --value 0.5ether --private-key $LOCAL_PRIVATE
```

又比如包装资产后解除包装，命令如下:

```bash
cast send $AGENCY "unwrap(address,uint256,bytes)" $LOCAL_ACCOUNT 1 "" --private-key $LOCAL_PRIVATE
```
