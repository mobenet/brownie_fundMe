from brownie import FundMe, accounts, MockV3Aggregator, network, config
from scripts.helpful_scripts import (
    FORKED_LOCAL_ENVIRONMENTS,
    deploy_mocks,
    get_account,
    deploy_mocks,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
)


def deploy_fundme():
    account = get_account()
    # pass the priceFeed address to our fundme contract
    # if we are on a persistent network like rinkeby, use the associated addres, otherwise deploy mocks
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        # meaning it is not ganache, but a testnet or real one
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
    else:  # we are on ganache or local blockchain for development
        deploy_mocks()
        price_feed_address = MockV3Aggregator[
            -1
        ].address  # -1 indica que utilitzis el contracte deployat mes recent

    fund_me = FundMe.deploy(
        price_feed_address,
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify"),
    )  # publish_source true fa que es verifiqui a etherscan el contracte
    print(f"Contract deployed to  {fund_me.address}")
    return fund_me


def main():
    deploy_fundme()
