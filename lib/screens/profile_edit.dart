import 'dart:convert';
import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/input_decorations.dart';
import 'package:active_ecommerce_flutter/custom/lang_text.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/custom/useful_elements.dart';
import 'package:active_ecommerce_flutter/helpers/file_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/repositories/address_repository.dart';
import 'package:active_ecommerce_flutter/data_model/city_response.dart';
import 'package:active_ecommerce_flutter/data_model/state_response.dart';
import 'package:active_ecommerce_flutter/data_model/country_response.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:toast/toast.dart';

class ProfileEdit extends StatefulWidget {
  @override
  _ProfileEditState createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  ScrollController _mainScrollController = ScrollController();
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSaving = false;
  
  // Basic Info Controllers
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  
  // Password Controllers
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _passwordConfirmController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  
  // Email Verification
  bool _isEmailVerified = false;
  String _verificationCode = "";
  TextEditingController _verificationCodeController = TextEditingController();
  
  // Image Upload
  final ImagePicker _picker = ImagePicker();
  XFile? _file;
  
  // Address Variables
  List<dynamic> _addressList = [];
  bool _isAddressInitial = true;
  
  // Address Form Controllers
  TextEditingController _addressController = TextEditingController();
  TextEditingController _postalCodeController = TextEditingController();
  TextEditingController _addressPhoneController = TextEditingController();
  TextEditingController _countryController = TextEditingController();
  TextEditingController _stateController = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  
  Country? _selectedCountry;
  MyState? _selectedState;
  City? _selectedCity;
  
  // Update Address Controllers
  List<TextEditingController> _updateAddressControllers = [];
  List<TextEditingController> _updatePostalCodeControllers = [];
  List<TextEditingController> _updatePhoneControllers = [];
  List<TextEditingController> _updateCountryControllers = [];
  List<TextEditingController> _updateStateControllers = [];
  List<TextEditingController> _updateCityControllers = [];
  List<Country?> _updateSelectedCountries = [];
  List<MyState?> _updateSelectedStates = [];
  List<City?> _updateSelectedCities = [];
  
  int? _defaultAddressId;

  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchAllData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _verificationCodeController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _addressPhoneController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchUserData();
    await _fetchAddresses();
    setState(() {
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  Future<void> _fetchUserData() async {
    try {
      var response = await ProfileRepository().getUserInfoResponse();
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        final user = response.data![0];
        _nameController.text = user.name ?? "";
        _phoneController.text = user.phone ?? "";
        _emailController.text = user.email ?? "";
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _fetchAddresses() async {
    try {
      var response = await AddressRepository().getAddressList();
      _addressList = response.addresses ?? [];
      
      // Find default address
      for (var address in _addressList) {
        if (address.set_default == 1) {
          _defaultAddressId = address.id;
          break;
        }
      }
      
      _setupUpdateControllers();
      _isAddressInitial = false;
      setState(() {});
    } catch (e) {
      print("Error fetching addresses: $e");
      _isAddressInitial = false;
    }
  }

  void _setupUpdateControllers() {
    _updateAddressControllers.clear();
    _updatePostalCodeControllers.clear();
    _updatePhoneControllers.clear();
    _updateCountryControllers.clear();
    _updateStateControllers.clear();
    _updateCityControllers.clear();
    _updateSelectedCountries.clear();
    _updateSelectedStates.clear();
    _updateSelectedCities.clear();
    
    for (var address in _addressList) {
      _updateAddressControllers.add(TextEditingController(text: address.address));
      _updatePostalCodeControllers.add(TextEditingController(text: address.postal_code ?? ""));
      _updatePhoneControllers.add(TextEditingController(text: address.phone ?? ""));
      _updateCountryControllers.add(TextEditingController(text: address.country_name ?? ""));
      _updateStateControllers.add(TextEditingController(text: address.state_name ?? ""));
      _updateCityControllers.add(TextEditingController(text: address.city_name ?? ""));
      _updateSelectedCountries.add(Country(id: address.country_id, name: address.country_name ?? ""));
      _updateSelectedStates.add(MyState(id: address.state_id, name: address.state_name ?? ""));
      _updateSelectedCities.add(City(id: address.city_id, name: address.city_name ?? ""));
    }
  }

  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchAllData();
  }

  // ============ IMAGE UPLOAD ============
  Future<void> _chooseAndUploadImage() async {
    var status = await Permission.camera.request();
    _file = await _picker.pickImage(source: ImageSource.gallery);
    
    if (_file == null) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.no_file_is_chosen,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }
    
    String base64Image = FileHelper.getBase64FormateFile(_file!.path);
    String fileName = _file!.path.split("/").last;
    
    var response = await ProfileRepository().getProfileImageUpdateResponse(base64Image, fileName);
    
    if (response.result == false) {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
    } else {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
      avatar_original.$ = response.path;
      setState(() {});
    }
  }

  // ============ UPDATE PROFILE ============
  Future<void> _onPressUpdate() async {
    var name = _nameController.text.trim();
    var phone = _phoneController.text.trim();
    
    if (name.isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_your_name,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }
    if (phone.isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_phone_number,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }
    
    setState(() => _isSaving = true);
    
    var post_body = jsonEncode({"name": name, "phone": phone});
    var response = await ProfileRepository().getProfileUpdateResponse(post_body: post_body);
    
    if (response.result == false) {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
    } else {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
      user_name.$ = name;
      user_phone.$ = phone;
    }
    
    setState(() => _isSaving = false);
  }

  // ============ UPDATE PASSWORD ============
  Future<void> _onPressUpdatePassword() async {
    var password = _passwordController.text;
    var passwordConfirm = _passwordConfirmController.text;
    
    if (password.isEmpty && passwordConfirm.isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_password,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }
    if (password.length < 6) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.password_must_contain_at_least_6_characters,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }
    if (password != passwordConfirm) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.passwords_do_not_match,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }
    
    setState(() => _isSaving = true);
    
    var post_body = jsonEncode({"password": password});
    var response = await ProfileRepository().getProfileUpdateResponse(post_body: post_body);
    
    if (response.result == false) {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
    } else {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
      _passwordController.clear();
      _passwordConfirmController.clear();
    }
    
    setState(() => _isSaving = false);
  }

  // ============ SEND EMAIL VERIFICATION ============
  Future<void> _sendEmailVerification() async {
    var email = _emailController.text.trim();
    if (email.isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_email_address,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      var response = await ProfileRepository().sendEmailVerificationCode(email);
      if (response['success'] == true) {
        ToastComponent.showDialog(response['message'] ?? "Verification code sent",
            gravity: Toast.center, duration: Toast.lengthLong);
      } else {
        ToastComponent.showDialog(response['message'] ?? "Failed to send code",
            gravity: Toast.center, duration: Toast.lengthLong);
      }
    } catch (e) {
      ToastComponent.showDialog("Failed to send verification code",
          gravity: Toast.center, duration: Toast.lengthLong);
    }
    
    setState(() => _isSaving = false);
  }

  // ============ VERIFY AND UPDATE EMAIL ============
  Future<void> _verifyAndUpdateEmail() async {
    var email = _emailController.text.trim();
    var code = _verificationCodeController.text.trim();
    
    if (code.isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_verification_code,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      var response = await ProfileRepository().verifyAndUpdateEmail(email, code);
      if (response['success'] == true) {
        ToastComponent.showDialog(response['message'] ?? "Email updated successfully",
            gravity: Toast.center, duration: Toast.lengthLong);
        user_email.$ = email;
        user_email.save();
      } else {
        ToastComponent.showDialog(response['message'] ?? "Verification failed",
            gravity: Toast.center, duration: Toast.lengthLong);
      }
    } catch (e) {
      ToastComponent.showDialog("Failed to verify email",
          gravity: Toast.center, duration: Toast.lengthLong);
    }
    
    setState(() => _isSaving = false);
  }

  // ============ ADDRESS CRUD OPERATIONS ============
  Future<void> _addAddress() async {
    if (_addressController.text.trim().isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_address_ucf,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }
    if (_selectedCountry == null) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.select_a_country,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }
    if (_selectedState == null) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.select_a_state,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }
    if (_selectedCity == null) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.select_a_city,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }
    
    setState(() => _isSaving = true);
    
    var response = await AddressRepository().getAddressAddResponse(
      address: _addressController.text.trim(),
      country_id: _selectedCountry!.id,
      state_id: _selectedState!.id,
      city_id: _selectedCity!.id,
      postal_code: _postalCodeController.text.trim(),
      phone: _addressPhoneController.text.trim(),
    );
    
    if (response.result == false) {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
    } else {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
      Navigator.pop(context);
      await _fetchAddresses();
      _clearAddressForm();
    }
    
    setState(() => _isSaving = false);
  }

  Future<void> _updateAddress(int index, int addressId) async {
    if (_updateAddressControllers[index].text.trim().isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_address_ucf,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }
    
    setState(() => _isSaving = true);
    
    var response = await AddressRepository().getAddressUpdateResponse(
      id: addressId,
      address: _updateAddressControllers[index].text.trim(),
      country_id: _updateSelectedCountries[index]!.id,
      state_id: _updateSelectedStates[index]!.id,
      city_id: _updateSelectedCities[index]!.id,
      postal_code: _updatePostalCodeControllers[index].text.trim(),
      phone: _updatePhoneControllers[index].text.trim(),
    );
    
    if (response.result == false) {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
    } else {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
      Navigator.pop(context);
      await _fetchAddresses();
    }
    
    setState(() => _isSaving = false);
  }

  Future<void> _deleteAddress(int addressId) async {
    var response = await AddressRepository().getAddressDeleteResponse(addressId);
    if (response.result == false) {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
    } else {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
      await _fetchAddresses();
    }
  }

  Future<void> _setDefaultAddress(int addressId) async {
    if (_defaultAddressId == addressId) return;
    
    var response = await AddressRepository().getAddressMakeDefaultResponse(addressId);
    if (response.result == false) {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
    } else {
      ToastComponent.showDialog(response.message, gravity: Toast.center, duration: Toast.lengthLong);
      _defaultAddressId = addressId;
      await _fetchAddresses();
    }
  }

  void _clearAddressForm() {
    _addressController.clear();
    _postalCodeController.clear();
    _addressPhoneController.clear();
    _countryController.clear();
    _stateController.clear();
    _cityController.clear();
    _selectedCountry = null;
    _selectedState = null;
    _selectedCity = null;
  }

  // ============ ADDRESS SELECTION METHODS ============
  void _onSelectCountry(Country country, StateSetter setModalState) {
    _selectedCountry = country;
    _selectedState = null;
    _selectedCity = null;
    setModalState(() {
      _countryController.text = country.name ?? "";
      _stateController.text = "";
      _cityController.text = "";
    });
  }

  void _onSelectState(MyState state, StateSetter setModalState) {
    _selectedState = state;
    _selectedCity = null;
    setModalState(() {
      _stateController.text = state.name ?? "";
      _cityController.text = "";
    });
  }

  void _onSelectCity(City city, StateSetter setModalState) {
    _selectedCity = city;
    setModalState(() {
      _cityController.text = city.name ?? "";
    });
  }

  // ============ BUILD UI ============
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: RefreshIndicator(
          color: MyTheme.accent_color,
          backgroundColor: Colors.white,
          onRefresh: _onPageRefresh,
          child: _isLoading
              ? _buildShimmer()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    children: [
                      _buildProfileImageSection(),
                      const SizedBox(height: 16),
                      _buildBasicInfoCard(),
                      const SizedBox(height: 16),
                      _buildChangePasswordCard(),
                      const SizedBox(height: 16),
                      _buildChangeEmailCard(),
                      const SizedBox(height: 16),
                      _buildAddressCard(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        AppLocalizations.of(context)!.edit_profile_ucf,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShimmerHelper().buildBasicShimmer(height: 120, width: 120, radius: 60),
          const SizedBox(height: 20),
          ShimmerHelper().buildBasicShimmer(height: 200, radius: 16),
          const SizedBox(height: 16),
          ShimmerHelper().buildBasicShimmer(height: 200, radius: 16),
          const SizedBox(height: 16),
          ShimmerHelper().buildBasicShimmer(height: 200, radius: 16),
          const SizedBox(height: 16),
          ShimmerHelper().buildBasicShimmer(height: 300, radius: 16),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    final avatarPath = avatar_original.$;
    final hasAvatar = avatarPath != null && avatarPath.isNotEmpty;
    
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MyTheme.accent_color, width: 2),
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.network(
                      avatarPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, size: 50, color: Colors.grey);
                      },
                    )
                  : const Icon(Icons.person, size: 50, color: Colors.grey),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _chooseAndUploadImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MyTheme.accent_color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MyTheme.accent_color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person_outline, size: 20, color: MyTheme.accent_color),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.basic_info,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildTextField(
                  label: AppLocalizations.of(context)!.name_ucf,
                  controller: _nameController,
                  hint: "John Doe",
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: AppLocalizations.of(context)!.phone_ucf,
                  controller: _phoneController,
                  hint: "+1234567890",
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _onPressUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent_color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(AppLocalizations.of(context)!.update_profile_ucf),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChangePasswordCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MyTheme.accent_color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.lock_outline, size: 20, color: MyTheme.accent_color),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.change_password,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildPasswordField(
                  label: AppLocalizations.of(context)!.new_password_ucf,
                  controller: _passwordController,
                  showPassword: _showPassword,
                  onToggle: () => setState(() => _showPassword = !_showPassword),
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  label: AppLocalizations.of(context)!.retype_password_ucf,
                  controller: _passwordConfirmController,
                  showPassword: _showConfirmPassword,
                  onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _onPressUpdatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent_color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(AppLocalizations.of(context)!.update_password_ucf),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChangeEmailCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MyTheme.accent_color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.email_outlined, size: 20, color: MyTheme.accent_color),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.change_email,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildTextField(
                  label: AppLocalizations.of(context)!.new_email_ucf,
                  controller: _emailController,
                  hint: "example@email.com",
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: AppLocalizations.of(context)!.verification_code,
                        controller: _verificationCodeController,
                        hint: "Enter code",
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _sendEmailVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: MyTheme.accent_color,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.verify_ucf),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _verifyAndUpdateEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent_color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(AppLocalizations.of(context)!.update_email_ucf),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MyTheme.accent_color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.location_on_outlined, size: 20, color: MyTheme.accent_color),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.addresses,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (_isAddressInitial)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_addressList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.location_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.no_address_found),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addressList.length,
              itemBuilder: (context, index) {
                final address = _addressList[index];
                final isDefault = address.id == _defaultAddressId;
                return GestureDetector(
                  onDoubleTap: () => _setDefaultAddress(address.id),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDefault ? MyTheme.accent_color : Colors.grey[200]!,
                        width: isDefault ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address.address ?? "", style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text("${address.city_name ?? ""}, ${address.state_name ?? ""}, ${address.country_name ?? ""}"),
                        const SizedBox(height: 4),
                        Text("${AppLocalizations.of(context)!.phone_ucf}: ${address.phone ?? ""}"),
                        if (address.postal_code != null && address.postal_code!.isNotEmpty)
                          Text("${AppLocalizations.of(context)!.postal_code}: ${address.postal_code}"),
                        if (isDefault)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: MyTheme.accent_color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.default_ucf,
                              style: TextStyle(fontSize: 10, color: MyTheme.accent_color),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => _showEditAddressDialog(index, address.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: () => _deleteAddress(address.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _showAddAddressDialog,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.add_new_address),
              style: OutlinedButton.styleFrom(
                foregroundColor: MyTheme.accent_color,
                side: BorderSide(color: MyTheme.accent_color),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: !showPassword,
          decoration: InputDecoration(
            hintText: "••••••••",
            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, size: 18),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddAddressDialog() {
    _clearAddressForm();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(AppLocalizations.of(context)!.add_new_address),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAddressFormField(
                    label: AppLocalizations.of(context)!.address_ucf,
                    controller: _addressController,
                    hint: "Enter address",
                  ),
                  const SizedBox(height: 12),
                  _buildTypeAheadField(
                    label: AppLocalizations.of(context)!.country_ucf,
                    controller: _countryController,
                    onSuggestionSelected: (country) => _onSelectCountry(country as Country, setModalState),
                    suggestionsCallback: (pattern) async {
                      var response = await AddressRepository().getCountryList(name: pattern);
                      return response.countries ?? [];
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTypeAheadField(
                    label: AppLocalizations.of(context)!.state_ucf,
                    controller: _stateController,
                    enabled: _selectedCountry != null,
                    onSuggestionSelected: (state) => _onSelectState(state as MyState, setModalState),
                    suggestionsCallback: (pattern) async {
                      if (_selectedCountry == null) return [];
                      var response = await AddressRepository().getStateListByCountry(
                        country_id: _selectedCountry!.id,
                        name: pattern,
                      );
                      return response.states ?? [];
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTypeAheadField(
                    label: AppLocalizations.of(context)!.city_ucf,
                    controller: _cityController,
                    enabled: _selectedState != null,
                    onSuggestionSelected: (city) => _onSelectCity(city as City, setModalState),
                    suggestionsCallback: (pattern) async {
                      if (_selectedState == null) return [];
                      var response = await AddressRepository().getCityListByState(
                        state_id: _selectedState!.id,
                        name: pattern,
                      );
                      return response.cities ?? [];
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAddressFormField(
                    label: AppLocalizations.of(context)!.postal_code,
                    controller: _postalCodeController,
                    hint: "Enter postal code",
                  ),
                  const SizedBox(height: 12),
                  _buildAddressFormField(
                    label: AppLocalizations.of(context)!.phone_ucf,
                    controller: _addressPhoneController,
                    hint: "Enter phone number",
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel_ucf),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : _addAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyTheme.accent_color,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(AppLocalizations.of(context)!.save_ucf),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditAddressDialog(int index, int addressId) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(AppLocalizations.of(context)!.edit_address),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAddressFormField(
                    label: AppLocalizations.of(context)!.address_ucf,
                    controller: _updateAddressControllers[index],
                    hint: "Enter address",
                  ),
                  const SizedBox(height: 12),
                  _buildTypeAheadField(
                    label: AppLocalizations.of(context)!.country_ucf,
                    controller: _updateCountryControllers[index],
                    initialValue: _updateSelectedCountries[index]?.name,
                    onSuggestionSelected: (country) {
                      _updateSelectedCountries[index] = country as Country;
                      _updateSelectedStates[index] = null;
                      _updateSelectedCities[index] = null;
                      setModalState(() {
                        _updateCountryControllers[index].text = country.name ?? "";
                        _updateStateControllers[index].clear();
                        _updateCityControllers[index].clear();
                      });
                    },
                    suggestionsCallback: (pattern) async {
                      var response = await AddressRepository().getCountryList(name: pattern);
                      return response.countries ?? [];
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTypeAheadField(
                    label: AppLocalizations.of(context)!.state_ucf,
                    controller: _updateStateControllers[index],
                    enabled: _updateSelectedCountries[index] != null,
                    onSuggestionSelected: (state) {
                      _updateSelectedStates[index] = state as MyState;
                      _updateSelectedCities[index] = null;
                      setModalState(() {
                        _updateStateControllers[index].text = state.name ?? "";
                        _updateCityControllers[index].clear();
                      });
                    },
                    suggestionsCallback: (pattern) async {
                      if (_updateSelectedCountries[index] == null) return [];
                      var response = await AddressRepository().getStateListByCountry(
                        country_id: _updateSelectedCountries[index]!.id,
                        name: pattern,
                      );
                      return response.states ?? [];
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTypeAheadField(
                    label: AppLocalizations.of(context)!.city_ucf,
                    controller: _updateCityControllers[index],
                    enabled: _updateSelectedStates[index] != null,
                    onSuggestionSelected: (city) {
                      _updateSelectedCities[index] = city as City;
                      setModalState(() {
                        _updateCityControllers[index].text = city.name ?? "";
                      });
                    },
                    suggestionsCallback: (pattern) async {
                      if (_updateSelectedStates[index] == null) return [];
                      var response = await AddressRepository().getCityListByState(
                        state_id: _updateSelectedStates[index]!.id,
                        name: pattern,
                      );
                      return response.cities ?? [];
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAddressFormField(
                    label: AppLocalizations.of(context)!.postal_code,
                    controller: _updatePostalCodeControllers[index],
                    hint: "Enter postal code",
                  ),
                  const SizedBox(height: 12),
                  _buildAddressFormField(
                    label: AppLocalizations.of(context)!.phone_ucf,
                    controller: _updatePhoneControllers[index],
                    hint: "Enter phone number",
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel_ucf),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _updateAddress(index, addressId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyTheme.accent_color,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(AppLocalizations.of(context)!.update_ucf),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeAheadField({
    required String label,
    required TextEditingController controller,
    required Function(dynamic) onSuggestionSelected,
    required Future<List<dynamic>> Function(String) suggestionsCallback,
    bool enabled = true,
    String? initialValue,
  }) {
    if (initialValue != null && controller.text.isEmpty) {
      controller.text = initialValue;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TypeAheadField(
          suggestionsCallback: suggestionsCallback,
          itemBuilder: (context, suggestion) {
            return ListTile(title: Text(suggestion.name ?? ""));
          },
          onSuggestionSelected: onSuggestionSelected,
          textFieldConfiguration: TextFieldConfiguration(
            controller: controller,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: "Select $label",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}