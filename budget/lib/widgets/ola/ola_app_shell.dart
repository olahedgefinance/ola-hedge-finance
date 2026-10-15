import 'package:budget/brand/ola_theme.dart';
import 'package:budget/struct/ola_navigation.dart';
import 'package:flutter/material.dart';

/// Presentation only. The caller owns routes, financial state and persistence.
class OlaAppShell extends StatefulWidget {
  const OlaAppShell(
      {super.key,
      required this.selectedPage,
      required this.onSelectPage,
      required this.body,
      required this.onSearch,
      this.shortcuts = const [],
      this.expandedSidebar = true,
      this.onToggleSidebar,
      this.pageLabels = const {},
      this.searchLabel = 'Search',
      this.settingsLabel = 'Settings',
      this.moreLabel = 'More',
      this.onCustomizeShortcut,
      this.customizeShortcutLabel = 'Select shortcut'});
  final int selectedPage;
  final ValueChanged<int> onSelectPage;
  final Widget body;
  final VoidCallback onSearch;
  final List<int> shortcuts;
  final bool expandedSidebar;
  final VoidCallback? onToggleSidebar;
  final Map<int, String> pageLabels;
  final String searchLabel, settingsLabel, moreLabel;
  final String customizeShortcutLabel;
  final ValueChanged<int>? onCustomizeShortcut;
  static double bottomBarHeight(BuildContext context,
      {String homeLabel = 'Home'}) {
    final media = MediaQuery.of(context);
    final labelWidth =
        ((media.size.width - media.viewPadding.horizontal) / 4 - 24)
            .clamp(1.0, double.infinity);
    var height = 80.0;
    for (final label in [homeLabel, 'Money', 'Plan', 'Wealth']) {
      final painter = TextPainter(
        text: TextSpan(
            text: label,
            style: const TextStyle(
                fontFamily: OlaTheme.fontFamily,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w700)),
        textDirection: Directionality.of(context),
        textScaler: media.textScaler,
      )..layout(maxWidth: labelWidth);
      final requiredHeight = 60 + painter.height.ceilToDouble();
      if (requiredHeight > height) height = requiredHeight;
      painter.dispose();
    }
    return height + media.viewPadding.bottom;
  }

  @override
  State<OlaAppShell> createState() => _OlaAppShellState();
}

class _OlaAppShellState extends State<OlaAppShell> {
  final Map<OlaSection, int> _lastPages = {};
  static const _sectionLabels = ['Home', 'Money', 'Plan', 'Wealth'];
  static const _icons = [
    Icons.home_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.event_note_outlined,
    Icons.bar_chart_rounded
  ];
  static const _labels = {
    0: 'Home',
    1: 'Transactions',
    2: 'Budgets',
    3: 'Settings',
    4: 'Settings',
    5: 'Subscriptions',
    6: 'Notifications',
    7: 'Analytics',
    8: 'Sign-in account',
    9: 'Accounts',
    10: 'Manage budgets',
    11: 'Categories',
    12: 'Titles',
    13: 'About',
    14: 'Goals',
    15: 'Manage goals',
    16: 'Scheduled',
    17: 'Loans'
  };
  String _label(int page) => widget.pageLabels[page] ?? _labels[page]!;
  void _remember() {
    final section = OlaNavigation.sectionFor(widget.selectedPage);
    if (section != null) _lastPages[section] = widget.selectedPage;
  }

  @override
  void initState() {
    super.initState();
    _remember();
  }

  @override
  void didUpdateWidget(OlaAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _remember();
  }

  void _select(int page) {
    FocusScope.of(context).unfocus();
    widget.onSelectPage(page);
  }

  Widget _section(OlaSection item,
          {bool vertical = false, bool collapsed = false}) =>
      OlaNavigationButton(
          key: ValueKey('ola-section-${item.name}'),
          label:
              item == OlaSection.home ? _label(0) : _sectionLabels[item.index],
          selected: OlaNavigation.sectionFor(widget.selectedPage) == item,
          icon: _icons[item.index],
          vertical: vertical,
          iconOnly: collapsed,
          onPressed: () =>
              _select(_lastPages[item] ?? OlaNavigation.pages(item).first));
  Widget _shortcuts() => PopupMenuButton<int>(
      key: const ValueKey('ola-shortcuts'),
      tooltip: widget.moreLabel,
      icon: const Icon(Icons.more_horiz),
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
      onSelected: (page) {
        if (page < 0) {
          widget.onCustomizeShortcut?.call(-page - 1);
        } else {
          _select(page);
        }
      },
      itemBuilder: (_) => [
            for (final page in OlaNavigation.shortcuts(
                [...widget.shortcuts, 6, 8, 10, 11, 12, 13, 15]))
              PopupMenuItem(
                  value: page,
                  key: ValueKey('ola-shortcut-$page'),
                  child: Text(_label(page))),
            if (widget.onCustomizeShortcut != null) ...[
              const PopupMenuDivider(),
              for (var slot = 0; slot < 3; slot++)
                PopupMenuItem(
                    value: -slot - 1,
                    key: ValueKey('ola-customize-$slot'),
                    child:
                        Text('${widget.customizeShortcutLabel} ${slot + 1}')),
            ],
          ]);
  Widget _brand() => Text('ÓLA',
      semanticsLabel: 'ÓLA HEDGE FINANCE',
      style: TextStyle(
          fontFamily: OlaTheme.fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary));
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final wide =
        MediaQuery.sizeOf(context).width >= OlaNavigation.sidebarBreakpoint;
    final section = OlaNavigation.sectionFor(widget.selectedPage);
    final siblings =
        section == null ? const <int>[] : OlaNavigation.pages(section);
    final collapsed = !widget.expandedSidebar;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: s.background,
      body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Fixed element positions keep the existing page subtree alive on resize.
        SizedBox(
            width: wide
                ? (collapsed
                        ? OlaNavigation.collapsedSidebarWidth
                        : OlaNavigation.sidebarWidth) +
                    MediaQuery.viewPaddingOf(context).left
                : 0,
            child: wide
                ? Material(
                    key: const ValueKey('ola-sidebar'),
                    color: s.surface,
                    child: SafeArea(
                        right: false,
                        child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                                horizontal: collapsed ? 8 : OlaSpacing.lg,
                                vertical: OlaSpacing.lg),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!collapsed) _brand(),
                                  if (widget.onToggleSidebar != null)
                                    IconButton(
                                        tooltip: collapsed
                                            ? 'Expand navigation'
                                            : 'Collapse navigation',
                                        onPressed: widget.onToggleSidebar,
                                        icon: Icon(collapsed
                                            ? Icons.menu_open
                                            : Icons.chevron_left)),
                                  const SizedBox(height: OlaSpacing.lg),
                                  for (final item in OlaSection.values)
                                    Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: OlaSpacing.xs),
                                        child: _section(item,
                                            collapsed: collapsed)),
                                  const Divider(height: OlaSpacing.xl),
                                  OlaNavigationButton(
                                      key: const ValueKey('ola-search'),
                                      label: widget.searchLabel,
                                      icon: Icons.search,
                                      iconOnly: collapsed,
                                      onPressed: widget.onSearch),
                                  OlaNavigationButton(
                                      key: const ValueKey('ola-settings'),
                                      label: widget.settingsLabel,
                                      selected: widget.selectedPage == 3 ||
                                          widget.selectedPage == 4,
                                      icon: Icons.settings_outlined,
                                      iconOnly: collapsed,
                                      onPressed: () => _select(4)),
                                  _shortcuts(),
                                ]))))
                : null),
        Expanded(
            child: Column(children: [
          if (!wide)
            Material(
                color: s.background,
                child: SafeArea(
                    bottom: false,
                    child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: OlaSpacing.lg, end: OlaSpacing.xs),
                        child: Row(children: [
                          Expanded(child: _brand()),
                          IconButton(
                              key: const ValueKey('ola-search'),
                              tooltip: widget.searchLabel,
                              onPressed: widget.onSearch,
                              icon: const Icon(Icons.search)),
                          IconButton(
                              key: const ValueKey('ola-settings'),
                              tooltip: widget.settingsLabel,
                              onPressed: () => _select(4),
                              icon: const Icon(Icons.settings_outlined)),
                          _shortcuts()
                        ])))),
          if (siblings.length > 1)
            SafeArea(
                bottom: false,
                top: wide,
                child: SingleChildScrollView(
                    key: ValueKey('ola-siblings-${section!.name}'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: OlaSpacing.lg, vertical: OlaSpacing.xxs),
                    child: Row(children: [
                      for (final page in siblings)
                        Padding(
                            padding: const EdgeInsetsDirectional.only(
                                end: OlaSpacing.xs),
                            child: OlaNavigationButton(
                                key: ValueKey('ola-page-$page'),
                                label: _label(page),
                                selected: widget.selectedPage == page,
                                onPressed: () => _select(page)))
                    ]))),
          Expanded(
              key: const ValueKey('ola-page-container'),
              // Legacy screens calculate their own constraints from viewport/sidebar.
              // A second width cap here would apply their padding twice.
              child: ClipRect(child: SizedBox.expand(child: widget.body))),
        ])),
      ]),
      bottomNavigationBar: wide
          ? null
          : Material(
              key: const ValueKey('ola-bottom-nav'),
              color: s.surface,
              child: SizedBox(
                  height: OlaAppShell.bottomBarHeight(context,
                      homeLabel: _label(0)),
                  child: SafeArea(
                      top: false,
                      child: Padding(
                          padding: const EdgeInsets.all(OlaSpacing.xs),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final item in OlaSection.values)
                                  Expanded(
                                      child: _section(item, vertical: true))
                              ]))))),
    );
  }
}

/// Shared accessible selected state for primary navigation and sibling tabs.
class OlaNavigationButton extends StatelessWidget {
  const OlaNavigationButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon,
      this.selected = false,
      this.vertical = false,
      this.iconOnly = false});
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool selected, vertical, iconOnly;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final text = Text(label,
        textAlign: vertical ? TextAlign.center : TextAlign.start,
        style: TextStyle(
            fontFamily: OlaTheme.fontFamily,
            fontSize: vertical ? 12 : 14,
            height: 1.2,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400));
    final symbol = icon == null ? null : Icon(icon, size: 22);
    return Semantics(
        selected: selected,
        button: true,
        label: iconOnly ? label : null,
        child: Tooltip(
            message: label,
            child: TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                    foregroundColor:
                        selected ? s.onPrimaryContainer : s.onSurfaceVariant,
                    backgroundColor:
                        selected ? s.primaryContainer : Colors.transparent,
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.symmetric(
                        horizontal: vertical || iconOnly ? 4 : 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(OlaRadii.md))),
                child: iconOnly
                    ? (symbol ?? text)
                    : vertical
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                if (symbol != null) symbol,
                                const SizedBox(height: 6),
                                Flexible(child: text)
                              ])
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            if (symbol != null) ...[
                              symbol,
                              const SizedBox(width: OlaSpacing.xs)
                            ],
                            Flexible(child: text)
                          ]))));
  }
}
