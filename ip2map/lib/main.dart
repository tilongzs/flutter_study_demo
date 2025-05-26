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
            List<Location> locations = await locationFromAddress(
              '$city, ${geoData.country}',
            );
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
        _mapController.move(
          LatLng(firstCity.latitude, firstCity.longitude),
          4.0,
        );
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  // 根据 IP 数量返回颜色
  Color getColorForIpCount(int count) {
    if (count >= 10) return Colors.red; // 10+ IPs: 红色
    if (count >= 5) return Colors.orange; // 5-9 IPs: 橙色
    if (count >= 2) return Colors.yellow; // 2-4 IPs: 黄色
    return Colors.green; // 1 IP: 绿色
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IP Address to City Map with Clustering'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // 地图区域
                Expanded(
                  flex: 3,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          initialCenter ?? LatLng(37.7749, -122.4194),
                      initialZoom: 4.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                      ),
                      MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          maxClusterRadius: 45,
                          size: const Size(40, 40),
                          markers: cityIpCounts.entries.map((entry) {
                            final cityData = entry.value;
                            return Marker(
                              width: 20,
                              height: 20,
                              point: LatLng(
                                cityData.latitude,
                                cityData.longitude,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: getColorForIpCount(
                                    cityData.count,
                                  ).withOpacity(0.7),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
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
                ),
                // 右侧列表区域
                Container(
                  width: 200,
                  color: Colors.grey[200],
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Top 10 Cities by IP Count',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: cityIpCounts.entries
                              .toList()
                              .asMap()
                              .entries
                              .where((entry) => entry.key < 10) // 限制前10
                              .map((entry) {
                                final index = entry.key;
                                final city = entry.value.key;
                                final count = entry.value.value.count;
                                return ListTile(
                                  leading: Text('${index + 1}.'),
                                  title: Text(city),
                                  trailing: Text('$count IPs'),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ],
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
