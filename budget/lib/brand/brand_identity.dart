class BrandIdentity {
  const BrandIdentity({
    required this.productName,
    required this.shortName,
    required this.description,
  });

  final String productName;
  final String shortName;
  final String description;
}

const BrandIdentity appBrand = BrandIdentity(
  productName: 'ÓLA HEDGE FINANCE',
  shortName: 'ÓLA HEDGE FINANCE',
  description: 'A budget and financial tracking application designed for you',
);
