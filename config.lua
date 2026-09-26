Config = {}
Config.StartingScore = 650
Config.MinScore = 300
Config.MaxScore = 850
Config.BillingCycleDays = 7
Config.MinimumPaymentPercent = 0.05
Config.MinimumPaymentFloor = 25
Config.LateFee = 35
Config.InterestEnabled = true
Config.ApplicationInquiryPenalty = 3
Config.OnTimePaymentGain = { min = 2, max = 7 }
Config.MissedPaymentPenalty = { [1] = 25, [2] = 40, [3] = 60 }
Config.SuspendAfterMisses = 2
Config.CloseAfterMisses = 3
Config.AdminPermission = 'admin'
Config.Command = 'credit'

Config.Cards = {
  secured = { label='AGC Secured', minScore=300, limit=500, apr=29.99 },
  starter = { label='AGC Starter', minScore=580, limit=1500, apr=26.99 },
  gold = { label='AGC Gold', minScore=650, limit=5000, apr=21.99 },
  platinum = { label='AGC Platinum', minScore=700, limit=10000, apr=17.99 },
  black = { label='AGC Black', minScore=760, limit=25000, apr=13.99 }
}


-- Payment selector settings
Config.PaymentSelector = {
  AllowCash = true,
  AllowDebit = true,
  AllowCredit = true,
  DebitAccount = 'bank'
}
