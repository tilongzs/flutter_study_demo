import 'package:flutter/material.dart';
import 'package:ipapi/ipapi.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IP to City Map with Clustering',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const IpMapPage(),
    );
  }
}

class IpMapPage extends StatefulWidget {
  const IpMapPage({super.key});

  @override
  _IpMapPageState createState() => _IpMapPageState();
}

class _IpMapPageState extends State<IpMapPage> {
  // 模拟一组 IP 地址
  final List<String> ipAddresses = [
    '172.217.0.0', // Google, Chicago
    '142.250.190.78', // Google, Mountain View
    '8.8.8.8', // Google, Mountain View
    '104.244.42.1', // Twitter, San Francisco
  ];

  // 存储城市及其 IP 计数
  Map<String, CityData> cityIpCounts = {};
  final MapController _mapController = MapController();
  LatLng? initialCenter;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchIpLocations();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // 获取 IP 地址的地理位置并统计
  Future<void> fetchIpLocations() async {
    setState(() {
      isLoading = true;
    });

    for (String ip in ipAddresses) {
      try {
        // 使用 ipapi 获取地理位置
        final geoData = await IpApi.getData(ip: ip);
        if (geoData != null && geoData.city != null) {
          String city = geoData.city!;
          double? lat = geoData.lat;
          double? lon = geoData.lon;

          // 如果经纬度为空，尝试使用 geocoding 包获取
          if (lat == null || lon == null) {
            List<Location> locations = await locationFromAddress('$city, ${geoData.country}');
            if (locations.isNotEmpty) {
              lat = locations.first.latitude;
              lon = locations.first.longitude;
            }
          }

          if (lat != null && lon != null) {
            setState(() {
              cityIpCounts.update(
                city,
                    (value) => CityData(
                  count: value.count + 1,
                  latitude: lat!,
                  longitude: lon!,
                  province: geoData.regionName ?? '',
                  country: geoData.country ?? '',
                ),
                ifAbsent: () => CityData(
                  count: 1,
                  latitude: lat!,
                  longitude: lon!,
                  province: geoData.regionName ?? '',
                  country: geoData.country ?? '',
                ),
              );
            });
          }
        }
      } catch (e) {
        print('Error processing IP $ip: $e');
      }
    }

    // 设置地图中心为第一个地点的经纬度
    if (cityIpCounts.isNotEmpty) {
      Timer(const Duration(milliseconds: 200), () {
        final firstCity = cityIpCounts.values.first;
        setState(() {
          initialCenter = LatLng(firstCity.latitude, firstCity.longitude);
        });
        _mapController.move(LatLng(firstCity.latitude, firstCity.longitude), 4.0);
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IP Address to City Map with Clustering'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(37.7749, -122.4194), // 默认中心（旧金山）
          initialZoom: 4.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 45,
              size: const Size(40, 40),
              markers: cityIpCounts.entries.map((entry) {
                final cityData = entry.value;
                return Marker(
                  width: 80.0,
                  height: 100.0,
                  point: LatLng(cityData.latitude, cityData.longitude),
                  child: Column(
                    children: [
                      Text(
                        '${entry.key}\n(${cityData.count})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.white70,
                        ),
                      ),
                      const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    ],
                  ),
                );
              }).toList(),
              builder: (context, markers) {
                return FloatingActionButton(
                  child: Text(markers.length.toString()),
                  onPressed: null,
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 用于存储城市数据的类
class CityData {
  final int count;
  final double latitude;
  final double longitude;
  final String province;
  final String country;

  CityData({
    required this.count,
    required this.latitude,
    required this.longitude,
    required this.province,
    required this.country,
  });
}