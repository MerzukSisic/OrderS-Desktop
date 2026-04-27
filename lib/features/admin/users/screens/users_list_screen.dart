import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/core/constants/app_constants.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/models/auth/user_model.dart';
import 'package:rs2_desktop/providers/users_accompaniments_providers.dart';
import 'package:rs2_desktop/routes/app_router.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  String? _roleFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<UsersProvider>();
    await provider.fetchUsers(role: _roleFilter);
  }

  void _applyFilters() {
    _loadData();
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    var filtered = users;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.fullName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (user.phoneNumber?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    return filtered;
  }

  void _showDeleteDialog(UserModel user) {
    final rootContext = context;
    final usersProvider = rootContext.read<UsersProvider>();
    final messenger = ScaffoldMessenger.of(rootContext);
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await usersProvider.deleteUser(user.id);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'User deleted successfully'
                        : 'Failed to delete user',
                  ),
                  backgroundColor: success
                      ? AppColors.success
                      : AppColors.error,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(UserModel user) async {
    final success = await context.read<UsersProvider>().updateUser(
      user.id,
      isActive: !user.isActive,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'User status updated' : 'Failed to update status',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UsersProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(provider.error!, style: TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final filteredUsers = _filterUsers(provider.users);

        return Column(
          children: [
            _buildHeader(provider.users.length),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: filteredUsers.isEmpty
                  ? _buildEmptyState()
                  : _buildUsersList(filteredUsers),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int totalCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Users Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalCount total users',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.adminUserCreate);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add User'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 150,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _roleFilter,
                    hint: const Text(
                      'All Roles',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    iconEnabledColor: AppColors.textSecondary,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Roles'),
                      ),
                      ...AppConstants.userRoles.map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _roleFilter = value);
                      _applyFilters();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<UserModel> users) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
          child: Text(
            user.fullName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: _getRoleColor(user.role),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            _buildRoleBadge(user.role),
            const SizedBox(width: 8),
            _buildStatusBadge(user.isActive),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(user.email),
              ],
            ),
            if (user.phoneNumber != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(user.phoneNumber!),
                ],
              ),
            ],
            const SizedBox(height: 2),
            Text(
              'Created: ${_formatDate(user.createdAt)}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                user.isActive ? Icons.toggle_on : Icons.toggle_off,
                color: user.isActive
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
              onPressed: () => _toggleUserStatus(user),
              tooltip: user.isActive ? 'Deactivate' : 'Activate',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.adminUserEdit,
                  arguments: user.id,
                );
              },
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _showDeleteDialog(user),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: _getRoleColor(role),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.error.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? AppColors.success : AppColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'Create your first user to get started',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.error;
      case 'waiter':
        return AppColors.primary;
      case 'kitchen':
        return AppColors.success;
      case 'bartender':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
