import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/business_provider.dart';
import '../../../services/business_service.dart';
import '../../../services/api_service.dart';
import '../../../utils/error_handler.dart';

class AddBranchScreen extends StatefulWidget {
  const AddBranchScreen({super.key});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authProvider = context.read<AuthProvider>();
        final businessProvider = context.read<BusinessProvider>();
        final businessId = businessProvider.businessId;
        
        if (businessId == null) {
          setState(() {
            _errorMessage = 'Business ID not found';
          });
          return;
        }

        /*
        final apiService = ApiService();
        if (authProvider.accessToken != null) {
          apiService.setAccessToken(authProvider.accessToken!);
        }
        final businessService = BusinessService(apiService);

        await businessService.createBranch(
          businessId,
          _nameController.text.trim(),
          _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          null,
        );
        */

        await businessProvider.createBranch(
           _nameController.text.trim(),
           _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
           null,
        );

        if (!mounted) return;
        
        // Refresh business provider
        // No longer needed
        // await businessProvider.refreshBranches();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branch created successfully')),
        );
        
        Navigator.of(context).pop(true);
      } catch (e) {
        setState(() {
          _errorMessage = ErrorHandler.formatException(e);
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Branch'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Branch Name *',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Branch name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Branch'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




