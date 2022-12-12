import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../../app/routes.dart';
import '../../../core/common.dart';
import '../../../service_locator.dart';
import '../../accounts/pages/accounts_page.dart';
import '../../budget_overview/pages/budget_overview_page.dart';
import '../../category/pages/category_list_page.dart';
import '../../debits/pages/debts_page.dart';
import '../../goal/widget/color_palette.dart';
import '../../search/pages/search_page.dart';
import '../../settings/widgets/user_profile_widget.dart';
import '../../summary/pages/summary_page.dart';
import '../../summary/widgets/welcome_name_widget.dart';
import '../bloc/home_bloc.dart';
import '../widgets/welcome_widget.dart';

late final Function(DateTimeRange dateTimeRange) dateTimeRange;

class LandingPage extends StatefulWidget {
  const LandingPage({
    Key? key,
  }) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  final HomeBloc homeBloc = locator.get<HomeBloc>();
  final ValueNotifier<DateTimeRange?> dateTimeRangeNotifier =
      ValueNotifier<DateTimeRange?>(null);

  late final Map<PageType, Widget> _pages = {
    PageType.home: const SummaryPage(),
    PageType.accounts: const AccountsPage(),
    PageType.category: const CategoryListPage(),
    PageType.budgetOverview: BudgetOverViewPage(
      categoryDataSource: locator.getAsync(),
      dateTimeRangeNotifier: dateTimeRangeNotifier,
    ),
    PageType.debts: const DebtsPage(),
  };

  DateTimeRange? dateTimeRange;
  void _handleClick(PageType page) {
    switch (page) {
      case PageType.accounts:
        context.goNamed(addAccountPath);
        break;
      case PageType.home:
        context.goNamed(addExpensePath);
        break;
      case PageType.category:
        context.goNamed(addCategoryPath);
        break;
      case PageType.debts:
        context.goNamed(addDebitName);
        break;
      case PageType.budgetOverview:
        _dateRangePicker();
        break;
    }
  }

  Widget _floatingActionButtonBig() {
    return BlocBuilder(
      bloc: homeBloc,
      builder: (context, state) {
        if (state is CurrentIndexState) {
          return FloatingActionButton.large(
            onPressed: () => _handleClick(state.currentPage),
            child: state.currentPage != PageType.budgetOverview
                ? const Icon(Icons.add)
                : const Icon(Icons.date_range),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<void> _dateRangePicker() async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 3)),
      end: DateTime.now(),
    );
    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDateRange: dateTimeRange ?? initialDateRange,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (_, child) {
        return Theme(
          data: ThemeData.from(colorScheme: Theme.of(context).colorScheme)
              .copyWith(
            appBarTheme: Theme.of(context).appBarTheme,
          ),
          child: child!,
        );
      },
    );
    if (newDateRange == null || newDateRange == dateTimeRange) return;
    dateTimeRange = newDateRange;
    dateTimeRangeNotifier.value = newDateRange;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => homeBloc,
      child: WillPopScope(
        onWillPop: () async {
          if (homeBloc.currentPage == PageType.home) {
            return true;
          }
          homeBloc.add(const CurrentIndexEvent(PageType.home));
          return false;
        },
        child: ScreenTypeLayout(
          breakpoints: const ScreenBreakpoints(
            tablet: 600,
            desktop: 700,
            watch: 300,
          ),
          mobile: Scaffold(
            appBar: AppBar(
              title: BlocBuilder(
                bloc: homeBloc,
                builder: (context, state) {
                  if (state is CurrentIndexState) {
                    return Text(
                      state.currentPage.name(context),
                      style: Theme.of(context)
                          .textTheme
                          .headline6
                          ?.copyWith(fontWeight: FontWeight.bold),
                    );
                  }
                  return Text('data');
                },
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: SearchPage(),
                    );
                  },
                ),
                GestureDetector(
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ColorPalette(),
                      ),
                    );
                  },
                  onTap: () => showModalBottomSheet(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width >= 700
                          ? 700
                          : double.infinity,
                    ),
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    context: context,
                    builder: (_) => const UserProfilePage(),
                  ),
                  child: const WelcomeWidget(),
                ),
              ],
            ),
            drawer: Drawer(
              child: BlocBuilder(
                bloc: homeBloc,
                builder: (context, state) {
                  PageType pageType = PageType.home;
                  if (state is CurrentIndexState) {
                    pageType = state.currentPage;
                  }
                  return ListView(
                    children: [
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.appTitle,
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ),
                      ListTile(
                        onTap: () {
                          homeBloc.add(const CurrentIndexEvent(PageType.debts));
                          Navigator.pop(context);
                        },
                        selected: pageType == PageType.debts,
                        title: Text(AppLocalizations.of(context)!.debtsLabel),
                        leading: const Icon(MdiIcons.accountCashOutline),
                      ),
                      ListTile(
                        onTap: () {
                          GoRouter.of(context).pushNamed(settingsPath);
                          Navigator.pop(context);
                        },
                        title:
                            Text(AppLocalizations.of(context)!.settingsLabel),
                        leading: const Icon(MdiIcons.cog),
                      )
                    ],
                  );
                },
              ),
            ),
            body: ContentWidget(pages: _pages),
            floatingActionButton: _floatingActionButtonBig(),
            bottomNavigationBar: BlocBuilder(
              bloc: homeBloc,
              builder: (context, state) {
                return Theme(
                  data: Theme.of(context)
                      .copyWith(splashFactory: NoSplash.splashFactory),
                  child: NavigationBar(
                    selectedIndex:
                        homeBloc.getIndexFromPage(homeBloc.currentPage),
                    onDestinationSelected: (index) => homeBloc.add(
                        CurrentIndexEvent(homeBloc.getPageFromIndex(index))),
                    destinations: [
                      NavigationDestination(
                        label: AppLocalizations.of(context)!.homeLabel,
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home),
                      ),
                      NavigationDestination(
                        label: AppLocalizations.of(context)!.accountsLabel,
                        icon: const Icon(Icons.credit_card_outlined),
                        selectedIcon: const Icon(Icons.credit_card),
                      ),
                      NavigationDestination(
                        label: AppLocalizations.of(context)!.categoryLabel,
                        icon: const Icon(Icons.category_outlined),
                        selectedIcon: const Icon(Icons.category),
                      ),
                      NavigationDestination(
                        label: AppLocalizations.of(context)!.budgetLabel,
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        selectedIcon: const Icon(Icons.account_balance_wallet),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          desktop: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                BlocBuilder(
                  bloc: homeBloc,
                  builder: (context, state) {
                    if (state is CurrentIndexState) {
                      return Drawer(
                        child: SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GestureDetector(
                                onTap: () => showModalBottomSheet(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width >= 700
                                            ? 700
                                            : double.infinity,
                                  ),
                                  isScrollControlled: true,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  context: context,
                                  builder: (_) => const UserProfilePage(),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onLongPress: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ColorPalette(),
                                          ),
                                        );
                                      },
                                      child: const WelcomeWidget(),
                                    ),
                                    const WelcomeNameWidget(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _handleClick(state.currentPage),
                                  icon: const Icon(MdiIcons.plus),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                  ),
                                  label: Text(
                                    AppLocalizations.of(context)!.addLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline6
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              NavigationBarItem(
                                title: AppLocalizations.of(context)!.homeLabel,
                                icon: MdiIcons.home,
                                isSelected: state.currentPage == PageType.home,
                                onPressed: () => homeBloc.add(
                                    const CurrentIndexEvent(PageType.home)),
                              ),
                              NavigationBarItem(
                                title:
                                    AppLocalizations.of(context)!.accountsLabel,
                                icon: MdiIcons.creditCard,
                                isSelected:
                                    state.currentPage == PageType.accounts,
                                onPressed: () => homeBloc.add(
                                    const CurrentIndexEvent(PageType.accounts)),
                              ),
                              NavigationBarItem(
                                title:
                                    AppLocalizations.of(context)!.categoryLabel,
                                icon: Icons.category,
                                isSelected:
                                    state.currentPage == PageType.category,
                                onPressed: () => homeBloc.add(
                                    const CurrentIndexEvent(PageType.category)),
                              ),
                              NavigationBarItem(
                                title:
                                    AppLocalizations.of(context)!.budgetLabel,
                                icon: MdiIcons.accountBadgeOutline,
                                isSelected: state.currentPage ==
                                    PageType.budgetOverview,
                                onPressed: () => homeBloc.add(
                                    const CurrentIndexEvent(
                                        PageType.budgetOverview)),
                              ),
                              NavigationBarItem(
                                title:
                                    AppLocalizations.of(context)!.budgetLabel,
                                icon: MdiIcons.accountCash,
                                isSelected: state.currentPage == PageType.debts,
                                onPressed: () => homeBloc.add(
                                    const CurrentIndexEvent(PageType.debts)),
                              )
                            ],
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
                Expanded(
                  child: ContentWidget(
                    pages: _pages,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationBarItem extends StatelessWidget {
  const NavigationBarItem({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).textTheme.headline6?.color;
    return Padding(
      padding: const EdgeInsets.only(
        right: 12,
        bottom: 8,
        left: 8,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                )
              : null,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Icon(icon, color: color),
              ),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .headline6
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContentWidget extends StatelessWidget {
  const ContentWidget({
    Key? key,
    required this.pages,
  }) : super(key: key);

  final Map<PageType, Widget> pages;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: BlocProvider.of<HomeBloc>(context),
      builder: (context, state) {
        if (state is CurrentIndexState) {
          return PageTransitionSwitcher(
            transitionBuilder: (
              child,
              primaryAnimation,
              secondaryAnimation,
            ) =>
                FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            ),
            duration: const Duration(milliseconds: 300),
            child: pages[state.currentPage],
          );
        }
        return SizedBox.fromSize();
      },
    );
  }
}
