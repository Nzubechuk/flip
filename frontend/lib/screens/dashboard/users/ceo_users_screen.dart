import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/business_service.dart';
import '../../../services/api_service.dart';
import '../../../utils/error_handler.dart';
import '../../../models/user.dart';
import '../../../models/business.dart';
import 'edit_user_screen.dart';
import '../../../utils/responsive_helper.dart';
import '../../../utils/toast_helper.dart';

class CeoUsersScreen extends StatefulWidget {
  final String? businessId;

  const CeoUsersScreen({super.key, this.businessId});

  @override
  State<CeoUsersScreen> createState() => _CeoUsersScreenState();
}

class _CeoUsersScreenState extends State<CeoUsersScreen> {


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = context.watch<BusinessProvider>();
    
    // Get businessId from provider if not provided
    final businessId = widget.businessId ?? businessProvider.businessId;
    
    // Load data if we have businessId and data is empty
    if (businessId != null && businessProvider.branches.isEmpty && !businessProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        businessProvider.loadBusinessData(businessId);
      });
    }

    final allStaff = [...businessProvider.managers, ...businessProvider.clerks];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Staffs'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              'Active Staff',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Expanded(
            child: _buildUsersList(allStaff),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddUserDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Staff'),
      ),
    );
  }

  Widget _buildUsersList(List<User> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No staffs yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<BusinessProvider>().refresh(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
          if (crossAxisCount > 1) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserCard(user, user.role);
              },
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserCard(user, user.role);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(User user, UserRole role) {
    final color = role == UserRole.manager ? Colors.green : Colors.orange;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToEdit(user, role),
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
                    child: Icon(
                      role == UserRole.manager ? Icons.people_outline : Icons.badge_outlined,
                      size: 24,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.firstName} ${user.lastName}',
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
                          '@${user.username}',
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
                        _navigateToEdit(user, role);
                      } else if (value == 'delete') {
                        _showDeleteUserDialog(user, role);
                      }
                    },
                    icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      user.email,
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
              const SizedBox(height: 8),
              if (user.branchName != null)
                Row(
                  children: [
                    const Icon(Icons.store_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        user.branchName!,
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  role.displayName,
                  style: TextStyle(
                    color: color,
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

  void _showAddUserDialog() {
    final businessProvider = context.read<BusinessProvider>();
    final businessId = widget.businessId ?? businessProvider.businessId;
    
    if (businessId == null) {
      if (mounted) {
        ToastHelper.showError(context, 'Business ID not found');
      }
      return;
    }

    _showAddUserRoleSelector(businessId);
  }

  void _showAddUserRoleSelector(String businessId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Staff Role',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.people, color: Colors.white),
                ),
                title: const Text('Manager'),
                subtitle: const Text('Can manage branch products and view analytics'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddUserForm(businessId, UserRole.manager);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.badge, color: Colors.white),
                ),
                title: const Text('Clerk'),
                subtitle: const Text('Can process sales and manage debts'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddUserForm(businessId, UserRole.clerk);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddUserForm(String businessId, UserRole role) {
    final _formKey = GlobalKey<FormState>();
    final _usernameController = TextEditingController();
    final _passwordController = TextEditingController();
    final _firstNameController = TextEditingController();
    final _lastNameController = TextEditingController();
    final _emailController = TextEditingController();
    Branch? _selectedBranch;
    bool _obscurePassword = true;
    bool _isLoading = false;
    String? _errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                role == UserRole.manager ? Icons.people : Icons.badge,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add ${role.displayName}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username *',
                        prefixIcon: Icon(Icons.account_circle),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (!value.contains('@')) {
                          return 'Valid email required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Consumer<BusinessProvider>(
                      builder: (context, provider, child) {
                        final branches = provider.branches;
                        if (branches.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'No branches available. Create a branch first.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          );
                        }
                        return DropdownButtonFormField<Branch>(
                          decoration: const InputDecoration(
                            labelText: 'Assign to Branch (Optional)',
                            prefixIcon: Icon(Icons.store),
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedBranch,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('No Branch')),
                            ...branches.map((b) => DropdownMenuItem(value: b, child: Text(b.name))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedBranch = value;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                    },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        try {
                          final businessProvider = context.read<BusinessProvider>();
                          
                          if (role == UserRole.manager) {
                            await businessProvider.createManager(
                              _usernameController.text.trim(),
                              _passwordController.text,
                              _firstNameController.text.trim(),
                              _lastNameController.text.trim(),
                              _emailController.text.trim(),
                              _selectedBranch?.id,
                            );
                          } else {
                            await businessProvider.createClerk(
                              _usernameController.text.trim(),
                              _passwordController.text,
                              _firstNameController.text.trim(),
                              _lastNameController.text.trim(),
                              _emailController.text.trim(),
                              _selectedBranch?.id,
                            );
                          }

                          if (mounted) {
                            Navigator.pop(dialogContext);
                            ToastHelper.showSuccess(context, '${role.displayName} added successfully');
                          }
                        } catch (e) {
                          setState(() {
                            _errorMessage = ErrorHandler.formatException(e);
                            _isLoading = false;
                          });
                        }
                      }
                    },
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_isLoading ? 'Adding...' : 'Add ${role.displayName}'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(User user, UserRole role) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditUserScreen(user: user, role: role),
      ),
    );
    // List updates are handled by the provider in EditUserScreen
  }

  void _showDeleteUserDialog(User user, UserRole role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.firstName} ${user.lastName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(user, role);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(User user, UserRole role) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final businessProvider = context.read<BusinessProvider>();
      final businessId = widget.businessId ?? businessProvider.businessId;
      
      if (businessId == null) {
        if (mounted) {
          ToastHelper.showError(context, 'Business ID not found');
        }
        return;
      }

      final apiService = ApiService();
      if (authProvider.accessToken != null) {
        apiService.setAccessToken(authProvider.accessToken!);
      }
      final businessService = BusinessService(apiService);

      if (role == UserRole.manager) {
        await businessProvider.deleteManagerData(user.userId);
      } else {
        await businessProvider.deleteClerkData(user.userId);
      }

      if (mounted) {
        ToastHelper.showSuccess(context, '${role.displayName} deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: ${e.toString()}')),
        );
      }
    }
  }
}

