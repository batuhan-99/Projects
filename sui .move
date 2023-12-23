module car::car_trade {
   
    use sui::transfer;
    use sui::coin::{Self as Coin, balance};
    use sui::object::{Self as Object, UID};
    use sui::balance::{Self as Balance, join, split};
    use sui::tx_context::{Self as TxContext, sender};

    const ETradeFailed: u64 = 1;

    struct Car has key {
        id:UID,
        kilometer:u32,
        painted_areas:u8,
        maintenance_count:u8,
        year:u16,
    }

    struct CarTrade has key {
        id:UID,
        car1:Car,
        car2:Car,
        trade_price:u64,
    }

    struct TraderCap has key { id:UID }

     fun start_trade(car1: Car, car2: Car, ctx: &mut TxContext) : CarTrade {
        
        transfer::transfer(TraderCap {
            id: Object::new(ctx),
        }, sender(ctx));

        let car1_score= calculate_score(&car1);
        let car2_score= calculate_score(&car2);

        let trade_price= car2_score * 100;

       CarTrade {
            id: Object::new(ctx),
            car1,
            car2,
            trade_price,
        }
    }

    public entry fun set_trade_price(trader_cap: &TraderCap, trade: &mut CarTrade, price: u64, ctx: &mut TxContext) {
        
        assert!(sender(trader_cap) == sender(ctx));

        trade.trade_price= price;
    }

   public entry fun finalize_trade(trader_cap: &TraderCap, trade: &mut CarTrade, ctx: &mut TxContext) {
        
        assert!(sender(trader_cap) == sender(ctx));

        let trader_balance = balance::balance_mut(trader_cap);
        assert!(balance::value(trader_balance) >= trade.trade_price, ETradeFailed);

        
        let paid = split(trader_balance, trade.trade_price);

       join(&mut car::car_shop::CarShop::balance_mut(ctx), paid);

        transfer::transfer(trade.car1, sender(ctx));
        transfer::transfer(trade.car2, sender(ctx));
    }

    fun calculate_score(car: &Car):u64 {
        let mut score= 0;
        score -= car.kilometer as i64;
        score -= car.painted_areas as i64 * 100;
        score += car.maintenance_count as i64 * 100;
        score -= ((2023 - car.year) * 100) as i64;

        if score < 0 {
            score= 0;
        }

        return score as u64;
    }
}
