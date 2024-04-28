# frozen_string_literal: true

module Langchain::Tool
  class QuicknodeBitcoin < Base
    #
    # Wrapper around QuickNode's Bitcoin Blockchain API
    #
    # Usage:
    #     quicknode_bitcoin = Langchain::Tool::QuicknodeBitcoin.new(url: ENV["QUICKNODE_BITCOIN_URL"])
    #
    NAME = "quicknode_bitcoin"
    ANNOTATIONS_PATH = Langchain.root.join("./langchain/tool/#{NAME}/#{NAME}.json").to_path

    def initialize(url:)
      @base_url = url
      # Initialize a Net::HTTP object
      @https = Net::HTTP.new(URI(@base_url).host, URI(@base_url).port)
      @https.use_ssl = true
    end

    # Decodes the raw transaction and provides chain information in JSON format.
    #
    # Parameters:
    #   - hexstring: String (required) - The transaction hex string to be decoded.
    #   - iswitness: Boolean (optional) - Indicates whether the transaction hex is a serialized witness transaction.
    #
    # Returns:
    #   JSON response containing the decoded transaction information.
    def decoderawtransaction(hexstring:, iswitness: false)
      send_request("decoderawtransaction", [hexstring, iswitness])
    end

    # Decodes a hex-encoded script.
    #
    # Parameters:
    #   - hexstring: String (required) - The hex-encoded script to be decoded.
    #
    # Returns:
    #   JSON response containing the decoded script information.
    def decodescript(hexstring:)
      send_request("decodescript", [hexstring])
    end

    # Estimates the smart fee per kilobyte to be paid for a transaction and also returns the number of blocks for which the estimate is valid.
    #
    # Parameters:
    #   - conf_target: Numeric (required) - Confirmation target in blocks.
    #   - estimate_mode: String (optional) - The fee estimate mode. By default, it is CONSERVATIVE.
    #
    # Returns:
    #   JSON response containing the estimated fee information.
    def estimatesmartfee(conf_target:, estimate_mode: "CONSERVATIVE")
      send_request("estimatesmartfee", [conf_target, estimate_mode])
    end

    # Returns the hash of the tip block in the most-work fully-validated chain.
    #
    # Parameters:
    #   This method does not accept any parameters.
    #
    # Returns:
    #   JSON response containing the hash of the tip block.
    def getbestblockhash
      send_request("getbestblockhash")
    end

    # Returns an object that contains information regarding blockchain processing in different states.
    #
    # Parameters:
    #   This method does not accept any parameters.
    #
    # Returns:
    #   JSON response containing information regarding blockchain processing.
    def getblockchaininfo
      send_request("getblockchaininfo")
    end

    # Returns the height of the fully-validated chain.
    #
    # Parameters:
    #   This method does not accept any parameters.
    #
    # Returns:
    #   The height of the fully-validated chain.
    def getblockcount
      send_request("getblockcount")
    end

    # Returns the hash of the block provided its height.
    #
    # Parameters:
    #   - height: Numeric (required) - The height index of the block in the blockchain.
    #
    # Returns:
    #   The hash of the block at the specified height.
    def getblockhash(height:)
      send_request("getblockhash", [height])
    end

    # Returns the header of the block given its hash.
    #
    # Parameters:
    #   - blockhash: String (required) - The hash of the block.
    #   - verbose: Boolean (optional) - Default is true. Set to true for a JSON object and false for hex-encoded data.
    #
    # Returns:
    #   If verbose is true, returns a JSON object containing the block header. Otherwise, returns the hex-encoded data.
    def getblockheader(blockhash:, verbose: true)
      send_request("getblockheader", [blockhash, verbose])
    end

    # Calculates per block statistics for a given window.
    #
    # Parameters:
    #   - hash_or_height: String/Numeric (required) - The block hash or height of the target block.
    #   - stats: Array (optional) - JSON array of values to filter from.
    #
    # Returns:
    #   JSON response containing per block statistics for the given block.
    def getblockstats(hash_or_height:, stats: [])
      send_request("getblockstats", [hash_or_height, stats].compact)
    end

    # Returns information about the block.
    #
    # Parameters:
    #   - blockhash: String (required) - The hash of the block.
    #   - verbosity: Numeric (optional) - Default is 1. Set to 0 for hex-encoded data, 1 for a JSON object, and 2 for a JSON object with transaction data.
    #
    # Returns:
    #   Information about the block.
    def getblock(blockhash:, verbosity: 1)
      send_request("getblock", [blockhash, verbosity])
    end

    # Returns information about all known chaintips in the block tree, including the main chain as well as orphaned branches.
    #
    # Parameters:
    #   This method does not accept any parameters.
    #
    # Returns:
    #   Information about all known chaintips in the block tree.
    def getchaintips
      send_request("getchaintips")
    end

    # Calculates data about the total number and rate of transactions in the chain.
    #
    # Parameters:
    #   - nblocks: Numeric (optional) - Default is one month. The window's size in number of blocks.
    #   - blockhash: String (optional) - Default is chain tip. The hash of the block that ends the window.
    #
    # Returns:
    #   Data about the total number and rate of transactions in the chain.
    def getchaintxstats(nblocks: nil, blockhash: nil)
      send_request("getchaintxstats", [nblocks, blockhash].compact)
    end

    # Returns the connection count to other nodes.
    #
    # Parameters:
    #   This method does not accept any parameters.
    #
    # Returns:
    #   The connection count to other nodes.
    def getconnectioncount
      send_request("getconnectioncount")
    end

    # Returns the proof-of-work difficulty as a multiple of the minimum difficulty.
    #
    # Parameters:
    #   This method does not accept any parameters.
    #
    # Returns:
    #   The proof-of-work difficulty.
    def getdifficulty
      send_request("getdifficulty")
    end

    # Returns the status of one or all available indexes actively running in the node.
    #
    # Parameters:
    #   - index_name: String (optional) - It filters results for an index with a specific name.
    #
    # Returns:
    #   The status of one or all available indexes actively running in the node.
    def getindexinfo(index_name: nil)
      send_request("getindexinfo", [index_name].compact)
    end

    # Returns an object that contains information regarding memory usage.
    #
    # Parameters:
    #   This method does not accept any parameters.
    #
    # Returns:
    #   Information regarding memory usage.
    def getmemoryinfo
      send_request("getmemoryinfo")
    end

    # Returns all in-mempool ancestors for a transaction in the mempool.
    #
    # Parameters:
    #   - txid: String (required) - The transaction id, and it must be in mempool.
    #   - verbose: Boolean (optional) - Default is false. Set to true for a JSON object and false for an array of transaction ids.
    #
    # Returns:
    #   All in-mempool ancestors for the specified transaction.
    def getmempoolancestors(txid:, verbose: false)
      send_request("getmempoolancestors", [txid, verbose])
    end

    # Returns all in-mempool descendants for a transaction in the mempool.
    #
    # Parameters:
    #   - txid: String (required) - The transaction id, and it must be in mempool.
    #   - verbose: Boolean (optional) - Default is false. Set to true for a JSON object and false for an array of transaction ids.
    #
    # Returns:
    #   All in-mempool descendants for the specified transaction.
    def getmempooldescendants(txid:, verbose: false)
      send_request("getmempooldescendants", [txid, verbose])
    end

    # Returns information about the active state of the TX memory pool.
    #
    # Parameters:
    #   This method does not accept any parameters.
    #
    # Returns:
    #   Information about the active state of the TX memory pool.
    def getmempoolinfo
      send_request("getmempoolinfo")
    end

    # Returns all transaction ids in memory pool.
    #
    # Parameters:
    #   - verbose: Boolean (optional) - Default is false. Set to true for a JSON object and false for an array of transaction ids.
    #   - mempool_sequence: Boolean (optional) - Default is false. Set to true to return a JSON object with transaction list and mempool sequence number attached.
    #
    # Returns:
    #   All transaction ids in memory pool.
    def getrawmempool(verbose: false, mempool_sequence: false)
      send_request("getrawmempool", [verbose, mempool_sequence])
    end

    # Returns the raw transaction data.
    #
    # Parameters:
    #   - txid: String (required) - The transaction id.
    #   - verbose: Integer (optional) - Default is 0. A numeric parameter that can take one of the following values: '0' for hex-encoded data, '1' for JSON object, and '2' for JSON object with fee and prevout.
    #   - blockhash: String (optional) - The block in which to look for the transaction.
    #
    # Returns:
    #   The raw transaction data.
    def getrawtransaction(txid:, verbose: 0, blockhash: nil)
      send_request("getrawtransaction", [txid, verbose, blockhash].compact)
    end

    # Ensures that the transactions are within block and returns proof of transaction inclusion.
    #
    # Parameters:
    #   - txids: Array (required) - An array of transaction hashes.
    #   - blockhash: String (optional) - If specified, looks for txid in the block with this hash.
    #
    # Returns:
    #   Proof of transaction inclusion.
    def gettxoutproof(txids:, blockhash: nil)
      send_request("gettxoutproof", [txids, blockhash].compact)
    end

    # Returns information about the unspent transaction output set.
    #
    # Parameters:
    #   - hash_type: String (optional) - It tells about which UTXO set hash should be calculated. Possible values: "hash_serialized_3", "none", "muhash". If not provided, default is set to be "hash_serialized_3".
    #   - hash_or_height: String/Integer (optional) - The block hash or height of the target height. If not provided, default is set to be the current best block.
    #   - use_index: Boolean (optional) - Use coinstatsindex if available. If not provided, default is set to be true.
    #
    # Returns:
    #   Information about the unspent transaction output set.
    def gettxoutsetinfo(hash_type: "hash_serialized_3", hash_or_height: nil, use_index: true)
      send_request("gettxoutsetinfo", [hash_type, hash_or_height, use_index].compact)
    end

    # Returns details about an unspent transaction output.
    #
    # Parameters:
    #   - txid: String (required) - The transaction id.
    #   - n: Numeric (required) - Vout number.
    #   - include_mempool: Boolean (optional) - Default is true. Whether to include the mempool.
    #
    # Returns:
    #   Details about the unspent transaction output.
    def gettxout(txid:, n:, include_mempool: true)
      send_request("gettxout", [txid, n, include_mempool])
    end

    # Submits a raw transaction (serialized, hex-encoded) to a node.
    #
    # Parameters:
    #   - hexstring: String (required) - The transaction hex string.
    #   - maxfeerate: Numeric/String (optional) - Default is 0.10. It rejects transactions with a fee rate higher than the specified value. It can be set to 0 to accept any fee rate.
    #
    # Returns:
    #   The transaction id if the transaction was accepted.
    def sendrawtransaction(hexstring:, maxfeerate: 0.10)
      send_request("sendrawtransaction", [hexstring, maxfeerate])
    end

    # Submits a package of raw transactions (serialized, hex-encoded) to the local node.
    #
    # Parameters:
    #   - package: Array (required) - An array of raw transactions.
    #
    # Returns:
    #   The result of submitting the package.
    def submitpackage(package:)
      send_request("submitpackage", [package])
    end

    # Returns the output of mempool acceptance tests, indicating if the mempool will accept serialized, hex-encoded raw transactions.
    #
    # Parameters:
    #   - rawtxs: Array (required) - An array of raw transactions in the form of a hex string.
    #   - maxfeerate: String/Numeric (optional) - Default is 0.10. It rejects transactions with a fee rate higher than the specified value, and it is set to 0 to accept any fee rate.
    #
    # Returns:
    #   The output of mempool acceptance tests.
    def testmempoolaccept(rawtxs:, maxfeerate: 0.10)
      send_request("testmempoolaccept", [rawtxs, maxfeerate])
    end

    # Returns information about the given bitcoin address.
    #
    # Parameters:
    #   - address: String (required) - The bitcoin address to validate.
    #
    # Returns:
    #   Information about the given bitcoin address.
    def validateaddress(address:)
      send_request("validateaddress", [address])
    end

    # Verifies a signed message.
    #
    # Parameters:
    #   - address: String (required) - The bitcoin address to use for the signature.
    #   - signature: String (required) - The signature provided by the signer in base64 encoding.
    #   - message: String (required) - The message that was signed.
    #
    # Returns:
    #   A boolean indicating whether the signature is valid for the given message and address.
    def verifymessage(address:, signature:, message:)
      send_request("verifymessage", [address, signature, message])
    end

    private

    # Sends an HTTP request to the API endpoint.
    #
    # Parameters:
    #   - body: Hash - The request body to be sent as JSON.
    #
    # Returns:
    #   JSON response from the API.
    def send_request(method, params = [])
      payload = {id: 1, jsonrpc: "2.0", method: method, params: params}
      pp payload
      pp "---------------"
      request = Net::HTTP::Post.new(URI(@base_url))
      request["Content-Type"] = "application/json"
      request.body = JSON.dump(payload)

      response = @https.request(request)

      case response
      when Net::HTTPSuccess
        response.read_body
      else
        raise "HTTP request failed: #{response.code} - #{response.message}"
      end
    end
  end
end
