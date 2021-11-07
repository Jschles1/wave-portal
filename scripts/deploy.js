const main = async () => {
    const waveContractFactory = await hre.ethers.getContractFactory('WavePortal');
    const vrfAddress = '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B';
    const linkToken = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709';
    const keyHash = '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311';
    const fee = hre.ethers.utils.parseEther('0.1');

    const waveContract = await waveContractFactory.deploy(vrfAddress, linkToken, keyHash, fee, {
        value: hre.ethers.utils.parseEther('0.001'),
    });

    await waveContract.deployed();

    console.log('WavePortal address: ', waveContract.address);

    await hre.run('fund-link', { contract: waveContract.address, linkaddress: linkToken });
};

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
};

runMain();
