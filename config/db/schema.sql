DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `facebook_id` varchar(255) NOT NULL,
  `access_token` varchar(255) NOT NULL,
  `birth_day` timestamp NOT NULL DEFAULT 0,
  `birth_day_month` tinyint(1) NOT NULL,
  `birth_day_day` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
