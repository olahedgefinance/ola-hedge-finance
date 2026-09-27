class BrandIdentity {
  const BrandIdentity({
    required this.productName,
    required this.shortName,
    required this.slug,
    required this.description,
  });

  final String productName;
  final String shortName;
  final String slug;
  final String description;
}

const BrandIdentity appBrand = BrandIdentity(
  productName: 'ÓLA HEDGE FINANCE',
  shortName: 'ÓLA HEDGE',
  slug: 'ola-hedge-finance',
  description:
      'A personal finance system for cash flow, budgeting, debt, savings, goals and wealth.',
);
