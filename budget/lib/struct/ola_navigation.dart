/// Presentation grouping only. Persisted route IDs belong to the legacy host.
enum OlaSection { home, money, plan, wealth }

abstract final class OlaNavigation {
  static const enabled =
      bool.fromEnvironment('OLA_PHASE6_UI', defaultValue: true);
  // Figma defines mobile/desktop examples, not the transition breakpoint.
  // Retain the inherited application's threshold.
  static const sidebarBreakpoint = 700.0;
  static const sidebarWidth = 220.0;
  static const collapsedSidebarWidth = 70.0;
  static const groups = {
    OlaSection.home: [0],
    OlaSection.money: [1, 9, 5, 16],
    OlaSection.plan: [2, 14],
    OlaSection.wealth: [7, 17],
  };

  static List<int> pages(OlaSection section) => groups[section]!;
  static OlaSection? sectionFor(int page) {
    for (final section in OlaSection.values) {
      if (pages(section).contains(page)) return section;
    }
    return null;
  }

  // Both legacy settings IDs must render one retained widget/GlobalKey owner.
  static int renderPage(int page) => page == 4 ? 3 : page;

  static bool validPage(int page) => page >= 0 && page < 18;
  static List<int> shortcuts(Iterable<int> pages) => pages
      .where(validPage)
      .map((page) => page == 3 ? 4 : page)
      .toSet()
      .toList();
}
