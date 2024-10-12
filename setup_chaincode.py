import asyncio
from hfc.fabric import Client

loop = asyncio.get_event_loop()

cli = Client(net_profile="network.json")
org1_admin = cli.get_user('shippingorg.blockport.com', 'Admin')


responses = loop.run_until_complete(cli.chaincode_install(
               requestor=org1_admin,
               peers=['peer0.shippingorg.blockport.com',
                      'peer1.shippingorg.blockport.com'],
               cc_path='Chaincode/build/libs',
               cc_name='contract',
               cc_version='v1.0',
               cc_type="JAVA"
               ))