import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/debt.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/business_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/debt_service.dart';
import '../../../utils/ui_helper.dart';
import '../../../utils/currency_formatter.dart';
import 'add_debt_screen.dart';
import '../../../utils/responsive_helper.dart';

class DebtsScreen extends StatefulWidget {
  final String? businessId;
  final String? branchId;
  const DebtsScreen({super.key, this.businessId, this.branchId});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color textColor = Colors.white;
    switch (status) {
      case 'PENDING':
        color = const Color(0xFFF59E0B); // Amber
        break;
      case 'PAID':
        color = const Color(0xFF10B981); // Emerald
        break;
      case 'RETURNED':
        color = const Color(0xFFEF4444); // Red
        break;
      default:
        color = const Color(0xFF64748B); // Slate
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Debt> _debts = [];
  bool _isLoading = true;
  String? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final businessProvider = context.read<BusinessProvider>();
      final apiService = ApiService();
      if (authProvider.accessToken != null) {
        apiService.setAccessToken(authProvider.accessToken!);
      }
      final debtService = DebtService(apiService);

      if (authProvider.user?.role == UserRole.ceo) {
        if (_selectedBranchId != null) {
          _debts = await debtService.getDebtsByBranch(_selectedBranchId!);
        } else if (widget.branchId != null) {
           _debts = await debtService.getDebtsByBranch(widget.branchId!);
        } else {
          _debts = await debtService.getDebtsByBusiness(businessProvider.businessId!);
        }
      } else {
        // Manager or Clerk
        final branchId = widget.branchId ?? authProvider.user?.branchId;
        if (branchId != null) {
          _debts = await debtService.getDebtsByBranch(branchId);
        }
      }

      // Filter to only show PENDING debts as requested
      _debts = _debts.where((debt) => debt.status == 'PENDING').toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading debts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsPaid(String debtId) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final apiService = ApiService();
      if (authProvider.accessToken != null) {
        apiService.setAccessToken(authProvider.accessToken!);
      }
      final debtService = DebtService(apiService);
      await debtService.markAsPaid(debtId);
      
      if (mounted) {
        setState(() {
          _debts.removeWhere((d) => d.id == debtId);
        });
        UiHelper.showSuccess(context, 'Debt marked as paid and sale recorded');
      }
    } catch (e) {
      if (mounted) {
        UiHelper.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _returnDebt(String debtId) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final apiService = ApiService();
      if (authProvider.accessToken != null) {
        apiService.setAccessToken(authProvider.accessToken!);
      }
      final debtService = DebtService(apiService);
      await debtService.returnDebt(debtId);
      
      if (mounted) {
        setState(() {
          _debts.removeWhere((d) => d.id == debtId);
        });
        UiHelper.showSuccess(context, 'Debt returned and stock restored');
      }
    } catch (e) {
      if (mounted) {
        UiHelper.showError(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final businessProvider = context.watch<BusinessProvider>();
    final branches = businessProvider.branches;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              'Manage Debts',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          if (authProvider.user?.role == UserRole.ceo)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Branch',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Branches')),
                        ...branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedBranchId = val);
                        _loadDebts();
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadDebts,
                    child: _debts.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(child: Text('No debts found')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _debts.length,
                            itemBuilder: (context, index) => _buildDebtCard(_debts[index]),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDebtScreen(
                branchId: authProvider.user?.role == UserRole.ceo ? _selectedBranchId : authProvider.user?.branchId,
              ),
            ),
          );
          if (result == true) _loadDebts();
        },
        label: const Text('Record Debt'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDebtCard(Debt debt) {
    final dateStr = DateFormat('MMM dd, yyyy HH:mm').format(debt.createdAt);
    final color = debt.status == 'PENDING' ? Colors.orange : Colors.green;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.1), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          backgroundColor: color.withOpacity(0.03),
          collapsedBackgroundColor: color.withOpacity(0.03),
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_outline,
              size: 24,
              color: color,
            ),
          ),
          title: Text(
            debt.consumerName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: debt.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(debt.totalAmount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: debt.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.name}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(CurrencyFormatter.format(item.price * item.quantity)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            if (debt.status == 'PENDING')
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _markAsPaid(debt.id),
                        icon: const Icon(Icons.check),
                        label: const Text('Paid'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _returnDebt(debt.id),
                        icon: const Icon(Icons.undo),
                        label: const Text('Return'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Remove ListPadding class at the bottom

