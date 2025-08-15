local mod = SMODS.current_mod
SMODS.Atlas({key = "modicon", path = "modicon.png", px = 31, py = 32, atlas_table = "ASSET_ATLAS"}):register()
SMODS.Atlas({key = "Umart", path = "Umart.png", px = 71, py = 95, atlas_table = "ASSET_ATLAS"}):register()

Umaconfig = SMODS.current_mod.config

SMODS.current_mod.extra_tabs = function() --Credits tab
    local scale = 0.5
    return {
        label = "Credits",
        tab_definition_function = function()
        return {
            n = G.UIT.ROOT,
            config = {
            align = "cm",
            padding = 0.05,
            colour = G.C.CLEAR,
            },
            nodes = {
            {
                n = G.UIT.R,
                config = {
                padding = 0,
                align = "cm"
                },
                nodes = {
                {
                    n = G.UIT.T,
                    config = {
                    text = "Programming: CampfireCollective",
                    shadow = false,
                    scale = scale,
                    colour = G.C.GREEN
                    }
                }
                }
            },
            {
                n = G.UIT.R,
                config = {
                padding = 0,
                align = "cm"
                },
                nodes = {
                {
                    n = G.UIT.T,
                    config = {
                    text = "Art: dottykitty",
                    shadow = false,
                    scale = scale,
                    colour = G.C.MONEY
                    }
                },
                }
            },
        }
        }
    end
    }
end


local function reset_ship_card()
    G.GAME.current_round.ship_card.rank = 'Ace'
    G.GAME.current_round.ship_card.id = 14
    local valid_ship_cards = {}
    for k, v in ipairs(G.playing_cards) do
        if not SMODS.has_no_rank(v) then
            valid_ship_cards[#valid_ship_cards+1] = v
        end
    end
    if valid_ship_cards[1] then 
        local ship_card = pseudorandom_element(valid_ship_cards, pseudoseed('dropkick'..G.GAME.round_resets.ante))
        G.GAME.current_round.ship_card.rank = ship_card.base.value
        G.GAME.current_round.ship_card.id = ship_card.base.id
    end
end
local function reset_legacy_card()
    local options = {}
    for k, suit in pairs(SMODS.Suits) do
            if (type(suit.in_pool) ~= "function" or suit:in_pool({ rank = "" })) then
                options[#options + 1] = k
            end
        end
    local legacy_suit1 = pseudorandom_element(options, pseudoseed('legacy'..G.GAME.round_resets.ante))
    options = {}
    if legacy_suit1 ~= G.GAME.current_round.legacy_card.suit1 and legacy_suit1 ~= G.GAME.current_round.legacy_card.suit2 then
        for k, suit in pairs(SMODS.Suits) do
            if k ~= legacy_suit1 and (type(suit.in_pool) ~= "function" or suit:in_pool({ rank = "" })) then
                options[#options + 1] = k
            end
        end
    else
        for k, suit in pairs(SMODS.Suits) do
            if
                k ~= G.GAME.current_round.legacy_card.suit1
                and k ~= G.GAME.current_round.legacy_card.suit2
                and (type(suit.in_pool) ~= "function" or suit:in_pool({ rank = "" }))
            then
                options[#options + 1] = k
            end
        end
	end
    local legacy_suit2 = pseudorandom_element(options, pseudoseed('legacy'..G.GAME.round_resets.ante))
    G.GAME.current_round.legacy_card.suit1 = legacy_suit1
    G.GAME.current_round.legacy_card.suit2 = legacy_suit2
end
mod.reset_game_globals = function(run_start)
	reset_ship_card()
    reset_legacy_card()
end

SMODS.Joker{ --Gold Ship
    name = "Gold Ship",
    key = "goldship",
    config = {
        extra = {
            kicks = {-2,-1,1,2,3,4,5}
        }
    },
    loc_txt = {
        ['name'] = 'Gold Ship',
        ['text'] = {
            [1] = 'Earn {C:money}money{} for each {C:attention}#1#',
            [2] = 'drawn to hand, rank',
            [3] = 'changes every round',
            [4] = '{C:inactive,S:0.8}Golshi decides how much'
        }
    },
    pos = {
        x = 1,
        y = 0
    },
    cost = 4,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {G.GAME.current_round.ship_card.rank}}
    end,

    calculate = function(self, card, context)
        if context.hand_drawn then
            for k, v in ipairs(context.hand_drawn) do
                if v:get_id() == G.GAME.current_round.ship_card.id then
                    local amount = pseudorandom_element(card.ability.extra.kicks,pseudoseed("dropkick"))
                    ease_dollars(amount)
                    card_eval_status_text(v, 'extra', nil, nil, nil, {message = '$'..amount, colour = G.C.MONEY})
                end
            end
        end
    end
}

SMODS.Joker{ --Haru Urara
    name = "Haru Urara",
    key = "haruurara",
    config = {
        extra = {
            odds = 1,
            hands = 1,
            odds_mod = 1
        }
    },
    loc_txt = {
        ['name'] = 'Haru Urara',
        ['text'] = {
            [1] = '{C:green}#1# in #2#{} chance to gain {C:blue}#3#{} hand',
            [2] = 'if {C:attention}final hand{} of round doesn\'t',
            [3] = 'pass {C:attention}blind requirement{}, then',
            [4] = 'decrease odds by {C:green}#4#',
            [5] = '{C:inactive}Resets each round'
        }
    },
    pos = {
        x = 0,
        y = 0
    },
    cost = 5,
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {G.GAME.probabilities.normal, card.ability.extra.odds, card.ability.extra.hands, card.ability.extra.odds_mod}}
    end,

    calculate = function(self, card, context)
        if context.after and G.GAME.current_round.hands_left == 0 then
            if (G.GAME.chips + math.floor(mult*hand_chips)) - G.GAME.blind.chips < 0 then
                if pseudorandom("tryingmybest") < G.GAME.probabilities.normal / card.ability.extra.odds then
                    ease_hands_played(1)
                    card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize{type = 'variable', key = 'a_hands', vars = {card.ability.extra.hands}}})
                    if not context.blueprint then
                        card.ability.extra.odds = card.ability.extra.odds + card.ability.extra.odds_mod
                        card_eval_status_text(card, 'extra', nil, nil, nil, {message = "+1 Odds!", colour = G.C.GREEN})
                    end
                end
            end

        elseif context.end_of_round and not context.blueprint and not context.individual and not context.repetition then
            card.ability.extra.odds = 1
            card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_reset'), colour = G.C.FILTER})
        end
    end
}

SMODS.Joker{ --Symboli Rudolf
    name = "Symboli Rudolf",
    key = "symbolirudolf",
    config = {
        extra = {
            
        }
    },
    loc_txt = {
        ['name'] = 'Symboli Rudolf',
        ['text'] = {
            [1] = 'Create up to {C:attention}2{} random',
            [2] = '{C:tarot}Tarot{} cards if no hands',
            [3] = 'remaining at end of round',
            [4] = '{C:inactive}Must have room'
        }
    },
    pos = {
        x = 2,
        y = 0
    },
    cost = 6,
    rarity = 2,
    blueprint_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {}}
    end,

    calculate = function(self, card, context)
        if context.end_of_round and not context.repetition and not context.individual and not context.blueprint then
            if G.GAME.current_round.hands_left == 0 then
                if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                    G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                    G.E_MANAGER:add_event(Event({
                        func = (function()
                            G.E_MANAGER:add_event(Event({
                                func = function() 
                                    local card = create_card('Tarot',G.consumeables, nil, nil, nil, nil, nil, 'yin')
                                    card:add_to_deck()
                                    G.consumeables:emplace(card)
                                    G.GAME.consumeable_buffer = 0
                                    return true
                                end}))   
                                card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.PURPLE})                       
                            return true
                        end)}))
                end
                if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                    G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                    G.E_MANAGER:add_event(Event({
                        func = (function()
                            G.E_MANAGER:add_event(Event({
                                func = function() 
                                    local card = create_card('Tarot',G.consumeables, nil, nil, nil, nil, nil, 'yin')
                                    card:add_to_deck()
                                    G.consumeables:emplace(card)
                                    G.GAME.consumeable_buffer = 0
                                    return true
                                end}))   
                                card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.PURPLE})                       
                            return true
                        end)}))
                end
            end
        end
    end
}

SMODS.Joker{ --Manhattan Cafe
    name = "Manhattan Cafe",
    key = "manhattancafe",
    config = {
        extra = {
            Xmult = 1,
            Xmult_mod = 0.25
        }
    },
    loc_txt = {
        ['name'] = 'Manhattan Cafe',
        ['text'] = {
            [1] = 'This Joker gains {C:white,X:red}X#2#{} Mult',
            [2] = 'if there is at least one {C:attention}empty',
            [3] = 'Joker slot when blind is selected',
            [4] = '{C:inactive}(Currently {C:white,X:red}X#1#{C:inactive} Mult)'
        }
    },
    pos = {
        x = 3,
        y = 0
    },
    cost = 7,
    rarity = 2,
    blueprint_compat = true,
    perishable_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.Xmult, card.ability.extra.Xmult_mod}}
    end,

    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            if G.jokers.config.card_limit - #G.jokers.cards > 0 then
                card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_mod
                card_eval_status_text((card), 'extra', nil, nil, nil, {message = localize{type = 'variable', key = 'a_xmult', vars = {card.ability.extra.Xmult}}, colour = G.C.RED})
            end

        elseif context.cardarea == G.jokers and context.joker_main and card.ability.extra.Xmult > 1 then
            return{
                message = localize{type='variable',key='a_xmult',vars={card.ability.extra.Xmult}},
                Xmult_mod = card.ability.extra.Xmult
            }
        end
    end
}

SMODS.Joker{ --Akikawa
    name = "Akikawa",
    key = "akikawa",
    config = {
        extra = {
            reps = 2
        }
    },
    loc_txt = {
        ['name'] = 'Akikawa',
        ['text'] = {
            [1] = 'Retrigger all played cards',
            [2] = '{C:attention}#1#{} times during the {C:attention}Boss Blind'
        }
    },
    pos = {
        x = 4,
        y = 0
    },
    cost = 8,
    rarity = 3,
    blueprint_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.reps}}
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.play and context.repetition and G.GAME.blind.boss then
            return{
                message = localize('k_again_ex'),
                repetitions = card.ability.extra.reps,
                card = card
            }
        end
    end
}


SMODS.Joker{ --Agnes Tachyon
    name = "Agnes Tachyon",
    key = "agnestachyon",
    config = {
        extra = {
            subjects = 3
        }
    },
    loc_txt = {
        ['name'] = "Agnes Tachyon",
        ['text'] = {
            [1] = 'If {C:attention}final {C:red}discard{} of round',
            [2] = 'has exactly {C:attention}#1#{} cards, they',
            [3] = 'gain random {C:attention}enhancements'
        }
    },
    pos = {
        x = 6,
        y = 0
    },
    cost = 5,
    rarity = 1,
    blueprint_compat = false,
    perishable_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.subjects}}
    end,

    calculate = function(self, card, context)
        if context.discard and G.GAME.current_round.discards_left == 2 and not context.blueprint then
            local eval =  function() return ((G.GAME.chips - G.GAME.blind.chips) < 0) and G.GAME.current_round.discards_left > 0  end
            juice_card_until(card, eval, true)
        
        elseif context.discard and not context.blueprint and G.GAME.current_round.discards_left == 1 and #context.full_hand == card.ability.extra.subjects then
            local enhancement = pseudorandom_element(G.P_CENTER_POOLS.Enhanced, pseudoseed('experiment'))
            if enhancement.key and G.P_CENTERS[enhancement.key] then
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.75,
                    func = function()
                        card_eval_status_text(context.other_card, 'extra', nil, nil, nil, {message = "Enhanced!", colour = G.C.PURPLE, instant = true})
                        context.other_card:set_ability(G.P_CENTERS[enhancement.key])
                        return true
                end}))
            end
        end
    end
}

SMODS.Joker{ --Bakushin
    name = "Bakushin",
    key = "bakushin",
    config = {
        extra = {
            mult = 15
        }
    },
    loc_txt = {
        ['name'] = "Bakushin",
        ['text'] = {
            [1] = '{C:mult}+#1#{} Mult on {C:attention}first',
            [2] = '{C:attention}hand{} of round'
        }
    },
    pos = {
        x = 5,
        y = 0
    },
    cost = 4,
    rarity = 1,
    blueprint_compat = true,
    perishable_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.mult}}
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.joker_main and G.GAME.current_round.hands_played == 0 then
            return{
                message = localize{type='variable',key='a_mult',vars={card.ability.extra.mult}},
                mult_mod = card.ability.extra.mult
            }
        end
    end
}

SMODS.Joker{ --Twin Turbo
    name = "Twin Turbo",
    key = "twinturbo",
    config = {
        extra = {
            doublejet = false
        }
    },
    loc_txt = {
        ['name'] = "Twin Turbo",
        ['text'] = {
            [1] = 'If played hand contains a {C:attention}Pair{},',
            [2] = 'cards held in hand give {C:blue}Chips',
            [3] = 'equal to {C:attention}double{} their {C:blue}Chips'
        }
    },
    pos = {
        x = 7,
        y = 0
    },
    cost = 7,
    rarity = 2,
    blueprint_compat = true,
    perishable_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.Xmult, card.ability.extra.Xmult_mod}}
    end,

    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            card.ability.extra.doublejet = next(context.poker_hands['Pair'])

        elseif card.ability.extra.doublejet and context.cardarea == G.hand and context.individual then
            if context.other_card.debuff then
                return {
                    message = localize('k_debuffed'),
                    colour = G.C.RED,
                    card = card,
                }
            else
                return {
                    h_chips = ((SMODS.has_no_rank(context.other_card) and 0 or context.other_card.base.nominal) + ((context.other_card.ability.bonus + (context.other_card.ability.perma_bonus or 0)) > 0 and (context.other_card.ability.bonus + (context.other_card.ability.perma_bonus or 0)) or 0)) * 2,
                    card = card
                }
            end

        elseif context.after and not context.blueprint then
            card.ability.extra.doublejet = false
        end
    end
}

SMODS.Joker{ --Tokai Teio
    name = "Tokai Teio",
    key = "tokaiteio",
    config = {
        extra = {
            fractures = 3
        }
    },
    loc_txt = {
        ['name'] = "Tokai Teio",
        ['text'] = {
            [1] = 'Destroy all played cards',
            [2] = 'in final hand of round',
            [3] = '{C:attention}#1#{C:inactive} uses remaining'
        }
    },
    pos = {
        x = 8,
        y = 0
    },
    cost = 6,
    rarity = 2,
    blueprint_compat = false,
    perishable_compat = true,
    eternal_compat = false,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.fractures}}
    end,

    calculate = function(self, card, context)
        if context.destroying_card and G.GAME.current_round.hands_left == 0 and not context.blueprint then
            return true

        elseif context.end_of_round and G.GAME.current_round.hands_left == 0 and not context.blueprint and not context.individual and not context.repetition then
            card.ability.extra.fractures = card.ability.extra.fractures - 1
            if card.ability.extra.fractures <= 0 then
                card_eval_status_text(card, 'extra', nil, nil, nil, {message = "Retired!",colour = G.C.BLUE})
                G.E_MANAGER:add_event(Event({
                    func = function()
                        play_sound('tarot1')
                        card.T.r = -0.2
                        card:juice_up(0.3, 0.4)
                        card.states.drag.is = true
                        card.children.center.pinch.x = true
                        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.3, blockable = false,
                            func = function()
                                G.jokers:remove_card(self)
                                card:remove()
                                card = nil
                            return true; end})) 
                        return true
                    end
                }))
            else
                card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize{type='variable',key='a_remaining',vars={card.ability.extra.fractures}},colour = G.C.BLUE})
            end
        end
    end
}

SMODS.Joker{ --TM Opera O
    name = "TM Opera O",
    key = "tmoperao",
    config = {
        extra = {
            Xmult = 1,
            Xmult_mod = 0.4
        }
    },
    loc_txt = {
        ['name'] = "TM Opera O",
        ['text'] = {
            [1] = 'This Joker gains {C:white,X:red}X#2#{} Mult',
            [2] = 'per {C:attention}consecutive{} hand played',
            [3] = 'with a scoring {C:attention}face{} card',
            [4] = '{C:inactive}(Currently {C:white,X:red}X#1#{C:inactive} Mult)'
        }
    },
    pos = {
        x = 9,
        y = 0
    },
    cost = 9,
    rarity = 3,
    blueprint_compat = true,
    perishable_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.Xmult, card.ability.extra.Xmult_mod}}
    end,

    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            local faces = false
            for i = 1, #context.scoring_hand do
                if context.scoring_hand[i]:is_face() then faces = true break end
            end
            if faces then
                card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_mod
                return {
                    card = card,
                    message = localize('k_upgrade_ex'),
                    colour = G.C.RED
                }
            else
                local last_mult = card.ability.extra.Xmult
                card.ability.extra.Xmult = 1
                if last_mult > 1 then 
                    return {
                        card = card,
                        message = localize('k_reset'),
                        colour = G.C.RED
                    }
                end
            end

        elseif context.cardarea == G.jokers and context.joker_main and card.ability.extra.Xmult > 1 then
            return{
                message = localize{type='variable',key='a_xmult',vars={card.ability.extra.Xmult}},
                Xmult_mod = card.ability.extra.Xmult
            }
        end
    end
}



SMODS.Joker{ --Special Week
    name = "Special Week",
    key = "specialweek",
    config = {
        extra = {
            seven = 7
        }
    },
    loc_txt = {
        ['name'] = "Special Week",
        ['text'] = {
            [1] = 'Each played {C:attention}#1#{} gains {C:chips}+#1#{} Chips',
            [2] = 'and gives {C:mult}+#1#{} Mult when scored'
        }
    },
    pos = {
        x = 0,
        y = 1
    },
    cost = 6,
    rarity = 1,
    blueprint_compat = true,
    perishable_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.seven}}
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.play and context.individual and context.other_card:get_id() == card.ability.extra.seven then
            context.other_card.ability.perma_bonus = context.other_card.ability.perma_bonus or 0
            context.other_card.ability.perma_bonus = context.other_card.ability.perma_bonus + card.ability.extra.seven
            card_eval_status_text(context.other_card, 'extra', nil, nil, nil, {message = localize('k_upgrade_ex'), colour = G.C.CHIPS})
            
            return {
                mult = card.ability.extra.seven,
                card = card
            }
        end
    end
}

SMODS.Joker{ --Maruzensky
    name = "Maruzensky",
    key = "maruzensky",
    config = {
        extra = {
            Xmult_mod = 0.5
        }
    },
    loc_txt = {
        ['name'] = "Maruzensky",
        ['text'] = {
            [1] = 'Played {C:attention}Steel Cards',
            [2] = 'gain {C:white,X:red}X#1#{} Mult',
            [3] = 'when scored'
        }
    },
    pos = {
        x = 1,
        y = 1
    },
    cost = 6,
    rarity = 1,
    blueprint_compat = true,
    perishable_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    enhancement_gate = 'm_steel',
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.Xmult_mod}}
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.play and context.individual and context.other_card.config.center.key == "m_steel" then
            context.other_card.ability.h_x_mult = context.other_card.ability.h_x_mult + card.ability.extra.Xmult_mod
            return {
                card = card,
                message = localize('k_upgrade_ex'),
                colour = G.C.RED
            }
        end
    end
}

SMODS.Joker{ --Oguri Cap
    name = "Oguri Cap",
    key = "oguricap",
    config = {
        extra = {
            mult = 0,
            mult_mod = 3,
            food = nil
        }
    },
    loc_txt = {
        ['name'] = "Oguri Cap",
        ['text'] = {
            [1] = 'When blind is selected,',
            [2] = 'a {C:attention}random card{} in deck',
            [3] = 'is destroyed and this',
            [4] = 'Joker gains {C:mult}+#2#{} Mult',
            [5] = '{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)'
        }
    },
    pos = {
        x = 2,
        y = 1
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = true,
    perishable_compat = false,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra.mult, card.ability.extra.mult_mod}}
    end,

    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            if #G.deck.cards > 0 then
                card.ability.extra.food = pseudorandom_element(G.deck.cards, pseudoseed('oguri'))
            end
            if card.ability.extra.food then
                card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
                if card.ability.extra.food == 'Glass Card' then 
                    G.E_MANAGER:add_event(Event({
                        trigger = "after",
                        delay = 0.2,
                        func = function()
                            card.ability.extra.food:shatter()
                            card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_eaten_ex'), colour = G.C.MULT})
                            return true
                        end,
                    }))
                else
                    G.E_MANAGER:add_event(Event({
                        trigger = "after",
                        delay = 0.2,
                        func = function()
                            play_sound('tarot1')
                            card.ability.extra.food:start_dissolve()
                            card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_eaten_ex'), colour = G.C.MULT})
                            return true
                        end,
                    }))
                end
            end
        elseif context.first_hand_drawn and not context.blueprint then
            card.ability.extra.food = nil

        elseif context.cardarea == G.jokers and context.joker_main and card.ability.extra.mult > 1 then
            return{
                message = localize{type='variable',key='a_mult',vars={card.ability.extra.mult}},
                mult_mod = card.ability.extra.mult
            }
        end
    end
}

SMODS.Joker{ --Silence Suzuka
    name = "Silence Suzuka",
    key = "silencesuzuka",
    config = {
        extra = {
            Xmult = 3,
            viewfromthelead = false
        }
    },
    loc_txt = {
        ['name'] = "Silence Suzuka",
        ['text'] = {
            [1] = '{C:white,X:red}X3{} Mult if this Joker',
            [2] = 'is the {C:attention}leftmost Joker'
        }
    },
    pos = {
        x = 3,
        y = 1
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = true,
    perishable_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        return {vars = {}}
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.joker_main then
            if not context.blueprint then
                card.ability.extra.viewfromthelead = G.jokers.cards[1] == card
            end
            if card.ability.extra.viewfromthelead then
                return {
                    message = localize{type='variable',key='a_xmult',vars={card.ability.extra.Xmult}},
                    Xmult_mod = card.ability.extra.Xmult
                }
            else
                return{
                    message = 'Not in Front!',
                    colour = G.C.RED
                }
            end
        elseif context.after and not context.blueprint then
            card.ability.extra.viewfromthelead = false
        end
    end
}

SMODS.Joker{ --Vodka x Daiwa Scarlet agenda
    name = "Our Legacy",
    key = "ourlegacy",
    config = {
        extra = {
            
        }
    },
    loc_txt = {
        ['name'] = "Our Legacy",
        ['text'] = {
            [1] = 'If {C:attention}first hand{} of round',
            [2] = 'contains both a scoring',
            [3] = '{V:1}#1#{} and {V:2}#2#{} card,',
            [4] = 'then upgrade level of',
            [5] = 'played poker hand'
        }
    },
    pos = {
        x = 4,
        y = 1
    },
    cost = 8,
    rarity = 3,
    blueprint_compat = true,
    perishable_compat = true,
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'Umart',

    loc_vars = function(self, info_queue, card)
        local vodkasuit, daiwasuit = G.GAME.current_round.legacy_card.suit1 and G.GAME.current_round.legacy_card.suit1 or "Hearts", G.GAME.current_round.legacy_card.suit2 and G.GAME.current_round.legacy_card.suit2 or "Spades"
        return {vars = {localize(vodkasuit, 'suits_plural'), localize(daiwasuit, 'suits_plural'), colours = {G.C.SUITS[vodkasuit], G.C.SUITS[daiwasuit]}} }
    end,

    calculate = function(self, card, context)
        if context.first_hand_drawn and not context.blueprint then
                local eval = function() return G.GAME.current_round.hands_played == 0 end
                juice_card_until(card, eval, true)
            
        elseif context.before and G.GAME.current_round.hands_played == 0 then
            local success1, success2 = false, false
            for k, v in ipairs(context.scoring_hand) do
                if v.ability.name ~= 'Wild Card' and v:is_suit(G.GAME.current_round.legacy_card.suit1) and not success1 then
                    success1 = true
                elseif v.ability.name ~= 'Wild Card' and v:is_suit(G.GAME.current_round.legacy_card.suit2) and not success2 then
                    success2 = true
                end
            end
            if not (success1 and success2) then
                for k, v in ipairs(context.scoring_hand) do
                    if v.ability.name == 'Wild Card' and v:is_suit(G.GAME.current_round.legacy_card.suit1) and not success1 then
                        success1 = true
                    elseif v.ability.name == 'Wild Card' and v:is_suit(G.GAME.current_round.legacy_card.suit2) and not success2 then
                        success2 = true
                    end
                end
            end
            if success1 and success2 then
                local text,disp_text = context.scoring_name
                card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('k_level_up_ex')})
                update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8, delay = 0.3}, {handname=localize(text, 'poker_hands'),chips = G.GAME.hands[text].chips, mult = G.GAME.hands[text].mult, level=G.GAME.hands[text].level})
                level_up_hand(context.blueprint_card or card, text, nil, 1)
            end
        end
    end
}