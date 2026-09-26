local QBCore = exports['qb-core']:GetCoreObject()
math.randomseed(os.time())

local function clamp(v) return math.max(Config.MinScore, math.min(Config.MaxScore, v)) end
local function ensureProfile(cid)
    MySQL.insert.await('INSERT IGNORE INTO agc_credit_profiles (citizenid, score) VALUES (?, ?)', {cid, Config.StartingScore})
    return MySQL.single.await('SELECT * FROM agc_credit_profiles WHERE citizenid=?', {cid})
end
local function history(cid, accountId, eventType, amount, delta, desc)
    MySQL.insert('INSERT INTO agc_credit_history (citizenid,account_id,event_type,amount,score_change,description) VALUES (?,?,?,?,?,?)', {cid,accountId,eventType,amount,delta,desc})
end
local function changeScore(cid, delta, reason, accountId)
    local p=ensureProfile(cid); local new=clamp(p.score+delta)
    MySQL.update.await('UPDATE agc_credit_profiles SET score=? WHERE citizenid=?',{new,cid})
    history(cid,accountId,'score_change',nil,new-p.score,reason)
    return new
end
local function makeCardNumber()
    return ('4%015d'):format(math.random(0,999999999999999))
end
local function getData(cid)
    local p=ensureProfile(cid)
    local accounts=MySQL.query.await('SELECT * FROM agc_credit_accounts WHERE citizenid=? ORDER BY id DESC',{cid})
    local hist=MySQL.query.await('SELECT * FROM agc_credit_history WHERE citizenid=? ORDER BY id DESC LIMIT 50',{cid})
    return {score=p.score,accounts=accounts,history=hist,cards=Config.Cards}
end

QBCore.Functions.CreateCallback('agc-credit:getData',function(src,cb)
    local P=QBCore.Functions.GetPlayer(src); if not P then return cb(nil) end
    cb(getData(P.PlayerData.citizenid))
end)

RegisterNetEvent('agc-credit:apply',function(cardType)
    local src=source; local P=QBCore.Functions.GetPlayer(src); local card=Config.Cards[cardType]
    if not P or not card then return end
    local cid=P.PlayerData.citizenid; local profile=ensureProfile(cid)
    local existing=MySQL.scalar.await("SELECT COUNT(*) FROM agc_credit_accounts WHERE citizenid=? AND card_type=? AND status!='closed'",{cid,cardType})
    if existing > 0 then return TriggerClientEvent('QBCore:Notify',src,'You already have this card.','error') end
    changeScore(cid,-Config.ApplicationInquiryPenalty,'Hard inquiry: '..card.label,nil)
    if profile.score < card.minScore then
        history(cid,nil,'application_declined',nil,-Config.ApplicationInquiryPenalty,card.label..' declined')
        return TriggerClientEvent('QBCore:Notify',src,('Declined. Minimum score: %d'):format(card.minScore),'error')
    end
    local id=MySQL.insert.await('INSERT INTO agc_credit_accounts (citizenid,card_type,card_number,credit_limit,due_at,last_billed_at) VALUES (?,?,?,?,DATE_ADD(NOW(), INTERVAL ? DAY),NOW())',{cid,cardType,makeCardNumber(),card.limit,Config.BillingCycleDays})
    history(cid,id,'application_approved',nil,-Config.ApplicationInquiryPenalty,card.label..' approved')
    TriggerClientEvent('QBCore:Notify',src,card.label..' approved!','success')
    TriggerClientEvent('agc-credit:refresh',src)
end)

RegisterNetEvent('agc-credit:pay',function(accountId,amount)
    local src=source; local P=QBCore.Functions.GetPlayer(src); amount=math.floor(tonumber(amount) or 0)
    if not P or amount<=0 then return end
    local cid=P.PlayerData.citizenid
    local a=MySQL.single.await('SELECT * FROM agc_credit_accounts WHERE id=? AND citizenid=?',{accountId,cid})
    if not a or a.status=='closed' and tonumber(a.balance)<=0 then return end
    amount=math.min(amount,math.floor(tonumber(a.balance)))
    if amount<=0 or not P.Functions.RemoveMoney('bank',amount,'credit-card-payment') then return TriggerClientEvent('QBCore:Notify',src,'Insufficient bank funds.','error') end
    local newBal=math.max(0,tonumber(a.balance)-amount); local newDue=math.max(0,tonumber(a.minimum_due)-amount)
    MySQL.update.await('UPDATE agc_credit_accounts SET balance=?, minimum_due=? WHERE id=?',{newBal,newDue,accountId})
    history(cid,accountId,'payment',amount,0,'Credit card payment')
    TriggerClientEvent('QBCore:Notify',src,('$%d payment posted.'):format(amount),'success'); TriggerClientEvent('agc-credit:refresh',src)
end)

-- Other server scripts can charge a card using this export.
exports('ChargeCard',function(citizenid,accountId,amount,description)
    amount=tonumber(amount) or 0
    local a=MySQL.single.await('SELECT * FROM agc_credit_accounts WHERE id=? AND citizenid=?',{accountId,citizenid})
    if not a or a.status~='active' or amount<=0 or tonumber(a.balance)+amount>tonumber(a.credit_limit) then return false end
    MySQL.update.await('UPDATE agc_credit_accounts SET balance=balance+? WHERE id=?',{amount,accountId})
    history(citizenid,accountId,'purchase',amount,0,description or 'Credit card purchase'); return true
end)
exports('GetCreditScore',function(srcOrCitizenId)
    local cid=srcOrCitizenId
    if type(srcOrCitizenId)=='number' then local P=QBCore.Functions.GetPlayer(srcOrCitizenId); if not P then return nil end; cid=P.PlayerData.citizenid end
    return ensureProfile(cid).score
end)

local function processBilling()
    local rows=MySQL.query.await("SELECT * FROM agc_credit_accounts WHERE status!='closed' OR balance>0")
    for _,a in ipairs(rows) do
        local due=MySQL.scalar.await('SELECT IF(due_at IS NOT NULL AND due_at <= NOW(),1,0) FROM agc_credit_accounts WHERE id=?',{a.id})
        if due==1 then
            local balance=tonumber(a.balance); local minDue=tonumber(a.minimum_due)
            if minDue>0 then
                local misses=a.missed_payments+1; local penalty=Config.MissedPaymentPenalty[math.min(misses,3)] or 60
                balance=balance+Config.LateFee; changeScore(a.citizenid,-penalty,'Missed credit card payment',a.id)
                local status=a.status; local reason=a.close_reason
                if misses>=Config.CloseAfterMisses then status='closed'; reason='Closed for nonpayment'
                elseif misses>=Config.SuspendAfterMisses then status='suspended' end
                MySQL.update.await('UPDATE agc_credit_accounts SET balance=?,missed_payments=?,status=?,close_reason=? WHERE id=?',{balance,misses,status,reason,a.id})
                history(a.citizenid,a.id,'missed_payment',minDue,-penalty,('Missed payment #%d'):format(misses))
            elseif balance>0 then
                changeScore(a.citizenid,math.random(Config.OnTimePaymentGain.min,Config.OnTimePaymentGain.max),'Account current',a.id)
            end
            local card=Config.Cards[a.card_type]; balance=tonumber(MySQL.scalar.await('SELECT balance FROM agc_credit_accounts WHERE id=?',{a.id})) or balance
            if Config.InterestEnabled and balance>0 and card then balance=balance+(balance*(card.apr/100)/52) end
            local minimum=balance>0 and math.max(Config.MinimumPaymentFloor,balance*Config.MinimumPaymentPercent) or 0
            minimum=math.min(minimum,balance)
            MySQL.update.await('UPDATE agc_credit_accounts SET balance=?,statement_balance=?,minimum_due=?,due_at=DATE_ADD(NOW(), INTERVAL ? DAY),last_billed_at=NOW() WHERE id=?',{balance,balance,minimum,Config.BillingCycleDays,a.id})
        end
    end
end
CreateThread(function() while true do Wait(60000); processBilling() end end)

-- Admin-menu integration: call this server export only after fivem_admin has validated ACE + Admin Duty.
exports('GetAdminCreditData', function(targetSource)
    local target = QBCore.Functions.GetPlayer(tonumber(targetSource))
    if not target then return nil end
    local d = getData(target.PlayerData.citizenid)
    local ci = target.PlayerData.charinfo or {}
    return {
        player = ((ci.firstname or '') .. ' ' .. (ci.lastname or '')):gsub('^%s*(.-)%s*$', '%1'),
        citizenid = target.PlayerData.citizenid,
        score = d.score,
        accounts = d.accounts,
        history = d.history
    }
end)

QBCore.Commands.Add('creditcycle','Force credit billing cycle (Admin)',{},false,function(src)
    MySQL.update.await("UPDATE agc_credit_accounts SET due_at=NOW() WHERE status!='closed' OR balance>0"); processBilling(); TriggerClientEvent('QBCore:Notify',src,'Credit billing cycle processed.','success')
end,Config.AdminPermission)
