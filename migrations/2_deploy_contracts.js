const BitmoonLaunchpad = artifacts.require('BitmoonLaunchpad.sol');
// const USDT = artifacts.require('TokenERC20.sol');
// const Token = artifacts.require('TokenERC20.sol');
// const SmartChef = artifacts.require('SmartChef.sol');

module.exports = async function(deployer, network, addressess) {
    // await deployer.deploy(USDT, 'USDT BM TEST', 'USDT-BMT');
    // const token = await USDT.deployed();
    // console.log('USDT-BMT Token address: ', token.address);

    // await deployer.deploy(Token, 'Private Token Test', 'PRTT');
    // const token2 = await Token.deployed();
    // console.log('Token address: ', token2.address);

    // await deployer.deploy(SmartChef);
    // const smartChef = await SmartChef.deployed();
    // console.log('Smart chef address: ', smartChef.address);

    await deployer.deploy(BitmoonLaunchpad, '10001');
    const launchpad = await BitmoonLaunchpad.deployed();
    console.log('Launchpad address: ', launchpad.address);

    // await token.transfer(launchpad.address, '1000000000000000000000000000');
    // await usdt.transfer(addressess[1], '1000000000000000000000000000');
    // await usdt.approve(launchpad.address, '115792089237316195423570985008687907853269984665640564039457584007913129639935', { from: addressess[1]});

    // await launchpad.addProject(
    //     token.address,
    //     '1000000000000000000000000000',
    //     '1000000000000000000000',
    //     '5000000000000000000000',
    //     '1636973825'
    // );

    // let projectDetail = await launchpad.getProjectDetail('1001');
    // console.log('Project detail: ', projectDetail);

    // await launchpad.updateProject(
    //     '1001',
    //     token.address,
    //     '1000000000000000000000000000',
    //     '1000000000000000000000',
    //     '6000000000000000000000',
    //     '1636973925'
    // );

    // projectDetail = await launchpad.getProjectDetail('1001');
    // console.log('Project detail after update: ', projectDetail);

    // await launchpad.addSupportedToken(
    //     '1001', 
    //     usdt.address, 
    //     '100000000000000000'
    // );

    // try {
    //     await launchpad.processBuyToken(
    //         '1001',
    //         usdt.address,
    //         '100000000000000000000'
    //         , {
    //             from: addressess[1]
    //         }
    //     )
    // }catch(e){
    //     console.log('Error 1: ', e.message);
    // }

    // await launchpad.addWhitelist('1001', addressess[1]);
    // try {
    //     await launchpad.processBuyToken(
    //         '1001',
    //         usdt.address,
    //         '50000000000000000000'
    //         , {
    //             from: addressess[1]
    //         }
    //     )
    // }catch(e){
    //     console.log('Error 2: ', e.message);
    // }

    // try {
    //     await launchpad.processBuyToken(
    //         '1001',
    //         usdt.address,
    //         '1000000000000000000000'
    //         , {
    //             from: addressess[1]
    //         }
    //     )
    // }catch(e){
    //     console.log('Error 3: ', e.message);
    // }

    // let balance = await usdt.balanceOf(addressess[1]);
    // console.log('USDT balance: ', balance.toString());

    // let tokenBalance = await token.balanceOf(addressess[1]);
    // console.log('Token balance: ', tokenBalance.toString());

    // try {
    //     await launchpad.processBuyToken(
    //         '1001',
    //         usdt.address,
    //         '100000000000000000000'
    //         , {
    //             from: addressess[1]
    //         }
    //     )
    // }catch(e) {
    //     console.log('Error: ', e);
    // } 

    // balance = await usdt.balanceOf(addressess[1]);
    // console.log('USDT balance after: ', balance.toString());

    // tokenBalance = await token.balanceOf(addressess[1]);
    // console.log('Token balance after: ', tokenBalance.toString());
}