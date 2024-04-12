// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.8;

import "suave-std/Suapp.sol";
import "suave-std/Context.sol";
import "suave-std/Transactions.sol";
import "suave-std/suavelib/Suave.sol";
import "solady/utils/LibString.sol";

contract ConfidentialStore is Suapp {
    Suave.DataId signingKeyRecord;
    string public constant PRIVATE_KEY = "KEY";
    uint public constant GOERLI_CHAINID = 5;
    string public constant GOERLI_CHAINID_STR = "0x5";
    string public constant INFURA_GOERLI_RPC = "https://goerli.infura.io/v3/1301ac078b854c40887bdc6d21d2e2da";

    function registerPrivateKeyOnchain(Suave.DataId _signingKeyRecord) public {
        signingKeyRecord = _signingKeyRecord;
    }

    function registerPrivateKey() public returns (bytes memory) {
        bytes memory keyData = Context.confidentialInputs();

        address[] memory peekers = new address[](1);
        peekers[0] = address(this);

        Suave.DataRecord memory record = Suave.newDataRecord(0, peekers, peekers, "private_key");
        Suave.confidentialStore(record.id, PRIVATE_KEY, keyData);

        return abi.encodeWithSelector(this.registerPrivateKeyOnchain.selector, record.id);
    }

    function sendTxOnchain() public emitOffchainLogs {}

    function sendTx() public returns (bytes memory) {
        Transactions.EIP155Request memory txn = Transactions.EIP155Request({
            to: address(0x00000000000000000000000000000000DeaDBeef),
            gas: 1000000,
            gasPrice: 500,
            value: 0,
            nonce: 1,
            data: bytes(""),
            chainId: GOERLI_CHAINID
        });

        bytes memory txRlp = Transactions.encodeRLP(txn);
        bytes memory signingKey = Suave.confidentialRetrieve(signingKeyRecord, PRIVATE_KEY);

        bytes memory txSigned = Suave.signEthTransaction(txRlp, GOERLI_CHAINID_STR, string(signingKey));
        bytes memory body = abi.encodePacked(
            '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["', 
            LibString.toHexString(txSigned), 
            '"],"id":1}'
        );
        /* solhint-enable */
        Suave.HttpRequest memory request;
        request.method = "POST";
        request.body = body;
        request.headers = new string[](1);
        request.headers[0] = "Content-Type: application/json";
        request.withFlashbotsSignature = false;
        request.url = INFURA_GOERLI_RPC;
        Suave.doHTTPRequest(request);

        return abi.encodeWithSelector(this.sendTxOnchain.selector);
    }
}
