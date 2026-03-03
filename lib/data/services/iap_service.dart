import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:waddle/domain/entities/iap_products.dart';

// ═══════════════════════════════════════════════════════════════════════
// IN-APP PURCHASE SERVICE
// ═══════════════════════════════════════════════════════════════════════
//
// Wraps the `in_app_purchase` plugin to provide a clean interface for:
//   • Querying available products & prices from the store
//   • Purchasing consumable drop bundles
//   • Purchasing / restoring auto-renewable subscriptions
//   • Delivering purchased drops to the HydrationCubit
//
// The service emits [IapEvent]s via a stream that the cubit listens to.
// ═══════════════════════════════════════════════════════════════════════

/// Events emitted by the IAP service for the cubit to handle.
sealed class IapEvent {}

/// Successfully purchased a drop bundle — deliver [drops] to the user.
class DropsDelivered extends IapEvent {
  final int drops;
  final String productId;
  DropsDelivered({required this.drops, required this.productId});
}

/// Subscription state changed (purchased, renewed, or expired).
class SubscriptionUpdated extends IapEvent {
  final bool isActive;
  final DateTime? expiryDate;
  final String? productId;
  SubscriptionUpdated({
    required this.isActive,
    this.expiryDate,
    this.productId,
  });
}

/// A purchase failed or was cancelled.
class PurchaseFailed extends IapEvent {
  final String message;
  PurchaseFailed(this.message);
}

/// A purchase is currently being processed (show loading).
class PurchaseProcessing extends IapEvent {}

/// Store products have been loaded.
class ProductsLoaded extends IapEvent {
  final List<ProductDetails> products;
  ProductsLoaded(this.products);
}

class IapService {
  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  final _eventController = StreamController<IapEvent>.broadcast();

  /// Stream of IAP events for the cubit to consume.
  Stream<IapEvent> get events => _eventController.stream;

  /// Cached product details from the store.
  final Map<String, ProductDetails> _products = {};

  /// Whether the store is available.
  bool _storeAvailable = false;
  bool get storeAvailable => _storeAvailable;

  IapService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  // ══════════════════════════════════════════════════════════════
  // Initialization
  // ══════════════════════════════════════════════════════════════

  Future<void> init() async {
    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) {
      debugPrint('IAP: Store not available');
      return;
    }

    // Listen for purchase updates
    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('IAP purchase stream error: $error');
        _eventController.add(PurchaseFailed('Purchase stream error: $error'));
      },
    );

    // Load products
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final allIds = Subscriptions.allProductIds;
    if (allIds.isEmpty) return;

    final response = await _iap.queryProductDetails(allIds);

    if (response.error != null) {
      debugPrint('IAP: Error loading products: ${response.error}');
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP: Products not found: ${response.notFoundIDs}');
    }

    _products.clear();
    for (final product in response.productDetails) {
      _products[product.id] = product;
    }

    _eventController.add(ProductsLoaded(response.productDetails));
    debugPrint('IAP: Loaded ${_products.length} products');
  }

  // ══════════════════════════════════════════════════════════════
  // Product queries
  // ══════════════════════════════════════════════════════════════

  /// Get the store price for a product. Returns null if not loaded.
  String? priceFor(String productId) => _products[productId]?.price;

  /// Whether a given product is available in the store.
  bool isProductAvailable(String productId) => _products.containsKey(productId);

  /// All loaded product details.
  List<ProductDetails> get allProducts => _products.values.toList();

  // ══════════════════════════════════════════════════════════════
  // Purchase flow
  // ══════════════════════════════════════════════════════════════

  /// Purchase a consumable drop bundle.
  Future<bool> purchaseDropBundle(DropBundle bundle) async {
    final product = _products[bundle.productId];
    if (product == null) {
      _eventController.add(PurchaseFailed(
        'Product not available. Please try again later.',
      ));
      return false;
    }

    final param = PurchaseParam(productDetails: product);
    try {
      _eventController.add(PurchaseProcessing());
      return await _iap.buyConsumable(purchaseParam: param);
    } catch (e) {
      _eventController.add(PurchaseFailed('Purchase failed: $e'));
      return false;
    }
  }

  /// Purchase or change a subscription.
  Future<bool> purchaseSubscription(SubscriptionTier tier) async {
    final product = _products[tier.productId];
    if (product == null) {
      _eventController.add(PurchaseFailed(
        'Subscription not available. Please try again later.',
      ));
      return false;
    }

    final param = PurchaseParam(productDetails: product);
    try {
      _eventController.add(PurchaseProcessing());
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      _eventController.add(PurchaseFailed('Subscription purchase failed: $e'));
      return false;
    }
  }

  /// Restore previous purchases (subscriptions).
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _eventController.add(PurchaseFailed('Restore failed: $e'));
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Purchase handling
  // ══════════════════════════════════════════════════════════════

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _eventController.add(PurchaseProcessing());
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Verify and deliver
          await _verifyAndDeliver(purchase);
          break;

        case PurchaseStatus.error:
          _eventController.add(PurchaseFailed(
            purchase.error?.message ?? 'Purchase failed',
          ));
          break;

        case PurchaseStatus.canceled:
          _eventController.add(PurchaseFailed('Purchase cancelled'));
          break;
      }

      // Complete pending purchases on Android
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    // ── Drop bundles (consumable) ──
    final bundle = DropBundles.byProductId(purchase.productID);
    if (bundle != null) {
      _eventController.add(DropsDelivered(
        drops: bundle.drops,
        productId: purchase.productID,
      ));
      debugPrint('IAP: Delivered ${bundle.drops} drops (${bundle.name})');
      return;
    }

    // ── Subscriptions ──
    if (Subscriptions.productIds.contains(purchase.productID)) {
      // For subscriptions, we trust the receipt on purchase/restore.
      // A production app should verify the receipt server-side.
      _eventController.add(SubscriptionUpdated(
        isActive: true,
        productId: purchase.productID,
        expiryDate: _estimateExpiry(purchase.productID),
      ));
      debugPrint('IAP: Subscription active (${purchase.productID})');
      return;
    }

    debugPrint('IAP: Unknown product ${purchase.productID}');
  }

  /// Estimate expiry based on product type. In production, parse
  /// the actual receipt for the real expiry date.
  DateTime? _estimateExpiry(String productId) {
    final now = DateTime.now();
    if (productId == Subscriptions.annual.productId) {
      return now.add(const Duration(days: 365));
    }
    if (productId == Subscriptions.monthly.productId) {
      return now.add(const Duration(days: 30));
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════
  // Subscription status check
  // ══════════════════════════════════════════════════════════════

  /// Check if the user has an active subscription by checking
  /// previous purchases. On Android this queries Google Play;
  /// on iOS it checks the receipt.
  Future<void> checkSubscriptionStatus() async {
    if (!_storeAvailable) return;

    // Restore purchases triggers _handlePurchaseUpdates which will
    // emit SubscriptionUpdated if any subscriptions are found.
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('IAP: Subscription check failed: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Cleanup
  // ══════════════════════════════════════════════════════════════

  void dispose() {
    _purchaseSub?.cancel();
    _eventController.close();
  }
}
