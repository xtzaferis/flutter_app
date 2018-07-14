import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:map_view/map_view.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as geoloc;

import '../helpers/ensure_visible.dart';
import '../../models/location_data.dart';
import '../../models/product.dart';

class LocationInput extends StatefulWidget {
  final Function setLocation;
  final Product product;

  LocationInput(this.setLocation, this.product);

  @override
  State<StatefulWidget> createState() {
    return _LocationInputState();
  }
}

class _LocationInputState extends State<LocationInput> {
  Uri _staticMapUri;
  LocationData _locationData;
  final FocusNode _addressInputFocusNode = FocusNode();
  final TextEditingController _addressInputController = TextEditingController();

  @override
  void initState() {
    _addressInputFocusNode.addListener(_updateLocation);
    if (widget.product != null) {
      _getStaticMap(widget.product.location.address, geocode: false);
    }
    super.initState();
  }

  @override
  void dispose() {
    _addressInputFocusNode.removeListener(_updateLocation);
    super.dispose();
  }

  void _getStaticMap(String address,
      {bool geocode = true, double lat, double lng}) async {
    if (address.isEmpty) {
      setState(() {
        _staticMapUri = null;
      });
      widget.setLocation(null);
      return;
    }
    if (geocode) {
      final Uri uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {'address': address, 'key': 'AIzaSyBEqqzYSgN89mochp0po6iOAY0OqacLwzw'},
      );
      final http.Response response = await http.get(uri);
      final decodedResponse = json.decode(response.body);
      final formattedAddress =
          decodedResponse['results'][0]['formatted_address'];
      final coords = decodedResponse['results'][0]['geometry']['location'];
      _locationData = LocationData(
          address: formattedAddress,
          latitude: coords['lat'],
          longitude: coords['lng']);
    } else if (lat == null && lng == null) {
      _locationData = widget.product.location;
    } else {
      _locationData =
          LocationData(address: address, latitude: lat, longitude: lng);
    }

    final StaticMapProvider staticMapViewProvider =
        StaticMapProvider('AIzaSyBEqqzYSgN89mochp0po6iOAY0OqacLwzw');
    final Uri staticMapUri = staticMapViewProvider.getStaticUriWithMarkers([
      Marker('position', 'Position', _locationData.latitude,
          _locationData.longitude)
    ],
        center: Location(_locationData.latitude, _locationData.longitude),
        width: 500,
        height: 300,
        maptype: StaticMapViewType.roadmap);
    widget.setLocation(_locationData);
    if (mounted) {
      setState(() {
        _addressInputController.text = _locationData.address;
        _staticMapUri = staticMapUri;
      });
    }
  }

  Future<String> _getAddress(double lat, double lng) async {
    final Uri uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'latlng': '${lat.toString()},${lng.toString()}',
        'key': 'AIzaSyBEqqzYSgN89mochp0po6iOAY0OqacLwzw'
      },
    );

    final http.Response response = await http.get(uri);
    final decodedResponse = json.decode(response.body);
    return decodedResponse['results'][0]['formatted_address'];
  }

  void _getUserLocation() async {
    final location = geoloc.Location();
    final currentLocation = await location.getLocation;
    final address = await _getAddress(
        currentLocation['latitude'], currentLocation['longitude']);
    _getStaticMap(address,
        geocode: false,
        lat: currentLocation['latitude'],
        lng: currentLocation['longitude']);
  }

  void _updateLocation() {
    if (!_addressInputFocusNode.hasFocus) {
      _getStaticMap(_addressInputController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        EnsureVisibleWhenFocused(
          focusNode: _addressInputFocusNode,
          child: TextFormField(
            focusNode: _addressInputFocusNode,
            controller: _addressInputController,
            validator: (String value) {
              if (_locationData == null || value.isEmpty) {
                return 'No valid location found.';
              }
            },
            decoration: InputDecoration(labelText: 'Address'),
          ),
        ),
        SizedBox(
          height: 10.0,
        ),
        FlatButton(
          onPressed: _getUserLocation,
          child: Text('Locate User'),
        ),
        SizedBox(
          height: 10.0,
        ),
        _staticMapUri == null
            ? Container()
            : Image.network(_staticMapUri.toString())
      ],
    );
  }
}
