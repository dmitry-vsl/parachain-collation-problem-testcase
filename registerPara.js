const {ApiPromise, RPCProvider, WsProvider, Keyring} = require('@polkadot/api');
const fs = require('fs')

const sudoAccountUri = '//Alice'

const GENESIS_FILE = process.env.GENESIS
const WASM_FILE = process.env.WASM
const NODE_URL= process.env.NODE_URL

const genesis = fs.readFileSync(GENESIS_FILE ,'ascii')
const wasm = fs.readFileSync(WASM_FILE,'ascii')

console.log('genesis', genesis)
console.log('wasm', wasm.slice(0,20) + '...' + wasm.slice(wasm.length-20,wasm.length))

async function wait(){
  return new Promise((resolve, reject) => {
    setTimeout(resolve, 1000)
  })
}

async function sendTxAndWait(account, tx){
  return new Promise(async (resolve, reject) => {
    const unsub = await tx.signAndSend(account, (result) => {
      if (result.status.isInBlock) {
        console.log(`Transaction included at blockHash ${result.status.asInBlock}`);
      } else if (result.status.isFinalized) {
        console.log(`Transaction finalized at blockHash ${result.status.asFinalized}`);
        //console.log('r', result.events.map(e => JSON.stringify(e.event)))
        unsub();
        resolve(result)
      } else {
        console.log('result', result.status.toString())
      }
    })
  })
}

;(async () => {

  await require('@polkadot/wasm-crypto').waitReady()
  const keyring = new Keyring({ type: 'sr25519' });
  const sudoAccount = keyring.addFromUri(sudoAccountUri);

  console.log('NODE_URL', NODE_URL)

  const wsProvider = new WsProvider(NODE_URL)

  const MAX_RETRY_TIME_SEC = 60
  const timeStart = new Date().getTime()
  do {
    console.log('Trying to connect, it may take some time')
    await wsProvider.connect()
    await wait()
  } while(!wsProvider.isConnected && (new Date().getTime() < timeStart + MAX_RETRY_TIME_SEC * 1000));
  if(!wsProvider.isConnected){
    console.error('Could not connect')
    process.exit(1)
  }
  console.log('api initialized')

  const api = await ApiPromise.create({ provider: wsProvider });


  /*
  export interface ParaGenesisArgs extends Struct {
      readonly genesisHead: Bytes;
      readonly validationCode: Bytes;
      readonly parachain: bool;
  }
  */
  const args ={
      genesisHead: genesis,
      validationCode: wasm,
      parachain: true,
    }
  const genesisArgs = api.createType("ParaGenesisArgs", args);
  console.log('send tx')
  await sendTxAndWait(
    sudoAccount,
    api.tx.sudo.sudo(api.tx.parasSudoWrapper.sudoScheduleParaInitialize(
      200, genesisArgs
    ))
  )
  process.exit(0)
})()
