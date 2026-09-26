CREATE TABLE IF NOT EXISTS `agc_credit_profiles` (
  `citizenid` varchar(50) NOT NULL,
  `score` int NOT NULL DEFAULT 650,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `agc_credit_accounts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `card_type` varchar(32) NOT NULL,
  `card_number` varchar(20) NOT NULL,
  `credit_limit` decimal(12,2) NOT NULL,
  `balance` decimal(12,2) NOT NULL DEFAULT 0,
  `statement_balance` decimal(12,2) NOT NULL DEFAULT 0,
  `minimum_due` decimal(12,2) NOT NULL DEFAULT 0,
  `due_at` datetime DEFAULT NULL,
  `missed_payments` int NOT NULL DEFAULT 0,
  `status` enum('active','suspended','closed') NOT NULL DEFAULT 'active',
  `close_reason` varchar(255) DEFAULT NULL,
  `last_billed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`), UNIQUE KEY `card_number` (`card_number`), KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `agc_credit_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `account_id` int DEFAULT NULL,
  `event_type` varchar(40) NOT NULL,
  `amount` decimal(12,2) DEFAULT NULL,
  `score_change` int NOT NULL DEFAULT 0,
  `description` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`), KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
