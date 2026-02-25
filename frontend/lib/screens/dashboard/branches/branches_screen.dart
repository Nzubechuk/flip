import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/business_provider.dart';
import '../../../utils/toast_helper.dart';
import '../../../services/business_service.dart';
import '../../../services/api_service.dart';
import '../../../utils/error_handler.dart';
import '../../../models/business.dart';
import 'add_branch_screen.dart';
import 'edit_branch_screen.dart';
import '../../../utils/responsive_helper.dart';
import '../../../utils/toast_helper.dart';

class BranchesScreen extends StatefulWidget {
  final String? businessId;

  const BranchesScreen({super.key, this.businessId});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  @override
  void initState() {
    super.initState();
    // business provider already loaded in parent (CeoHomeScreen)
    // or we could trigger load here if needed, but watch() handles updates
  }

  // _loadBranchesFromProvider removed
  
  Future<void> _refreshBranches() async {
    try {
      await context.read<BusinessProvider>().refreshBranches();
    } catch (e) {
      if (mounted) {
      if (mounted) {
         ToastHelper.showError(context, 'Error refreshing branches: $e');
      }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = context.watch<BusinessProvider>();
    final branches = businessProvider.branches;
    final isLoading = businessProvider.isLoading;
    
    // If provider has data, use it. Otherwise wait for load or refresh.

    return Scaffold(
      body: isLoading && branches.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await businessProvider.loadBusinessData(widget.businessId ?? businessProvider.businessId!);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Text(
                      'Manage Branches',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: branches.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.store_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No branches yet',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add your first branch to get started',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
                              if (crossAxisCount > 1) {
                                return GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.3,
                                  ),
                                  itemCount: branches.length,
                                  itemBuilder: (context, index) => _buildBranchCard(branches[index]),
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: branches.length,
                                itemBuilder: (context, index) => _buildBranchCard(branches[index]),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddBranchScreen(),
            ),
          );
          if (result == true) {
            // AddBranch updates provider directly, so no refresh needed usually.
            // But to be safe or if update failed:
            // _refreshBranches(); 
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Branch'),
      ),
    );
  }

  Widget _buildBranchCard(Branch branch) {
    final color = Theme.of(context).colorScheme.primary;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToEdit(branch),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.withOpacity(0.03),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.store_outlined, size: 24, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Branch Office',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    padding: EdgeInsets.zero,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: const [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: const [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToEdit(branch);
                      } else if (value == 'delete') {
                        _showDeleteDialog(branch);
                      }
                    },
                    icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      branch.location ?? 'No location provided',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEdit(Branch branch) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditBranchScreen(branch: branch),
      ),
    );
    if (result == true) {
      _refreshBranches();
    }
  }

  void _showDeleteDialog(Branch branch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text('Are you sure you want to delete ${branch.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBranch(branch);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBranch(Branch branch) async {
    try {
      final businessProvider = context.read<BusinessProvider>();
      await businessProvider.deleteBranch(branch.id);
      
      if (mounted) {
        ToastHelper.showSuccess(context, 'Branch deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, ErrorHandler.formatException(e));
      }
    }
  }
}
