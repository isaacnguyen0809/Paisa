import 'package:flutter/material.dart';

import 'package:paisa/core/common_enum.dart';
import 'package:paisa/features/account/data/model/account_model.dart';

List<AccountModel> defaultAccountsData() {
  return [
    AccountModel(
      name: 'User name',
      bankName: 'Cash',
      cardType: AccountType.cash,
      color: Colors.primaries[0].value,
    ),
    AccountModel(
      name: 'User name',
      bankName: 'Bank',
      color: Colors.primaries[1].value,
    ),
    AccountModel(
      name: 'User name',
      bankName: 'Wallet',
      cardType: AccountType.wallet,
      color: Colors.primaries[2].value,
    ),
  ];
}
