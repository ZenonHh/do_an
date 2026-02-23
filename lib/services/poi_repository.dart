import 'package:latlong2/latlong.dart';
import '../models/poi_model.dart';

class POIRepository {
  static List<POI> getTourPoints() {
    return [
      POI(
        id: '1',
        name: "Hồ Gươm (Hồ Hoàn Kiếm)",
        location: const LatLng(21.0285, 105.8542),
        radius: 150,
        priority: 2,
        description: "Hồ Gươm được coi là trái tim của Thủ đô Hà Nội, gắn liền với truyền thuyết vua Lê Lợi trả gươm báu cho Rùa Vàng.",
        imageUrl: "https://vcdn1-dulich.vnecdn.net/2022/05/27/ho-guom-7452-1653641214.jpg",
        mapLink: "https://www.google.com/maps/search/?api=1&query=21.0285,105.8542",
        content: "Chào mừng bạn đến với Hồ Gươm, trái tim của thủ đô Hà Nội. Nơi đây gắn liền với truyền thuyết Trả gươm cho Rùa Vàng của vua Lê Lợi.",
      ),
      POI(
        id: '2',
        name: "Nhà Thờ Lớn Hà Nội",
        location: const LatLng(21.0288, 105.8490),
        radius: 80,
        priority: 1,
        description: "Công trình kiến trúc Gothic tiêu biểu tại Hà Nội, được xây dựng theo mẫu Nhà thờ Đức Bà Paris.",
        imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/St._Joseph%27s_Cathedral%2C_Hanoi.jpg/800px-St._Joseph%27s_Cathedral%2C_Hanoi.jpg",
        mapLink: "https://www.google.com/maps/search/?api=1&query=21.0288,105.8490",
        content: "Bạn đang đứng trước Nhà Thờ Lớn Hà Nội, một công trình kiến trúc Gothic độc đáo được hoàn thành vào năm 1886.",
      ),
      POI(
        id: '3',
        name: "Văn Miếu - Quốc Tử Giám",
        location: const LatLng(21.0294, 105.8355),
        radius: 200,
        priority: 1,
        description: "Trường đại học đầu tiên của Việt Nam, nơi thờ Khổng Tử và các bậc hiền triết.",
        imageUrl: "https://vcdn1-dulich.vnecdn.net/2021/04/23/van-mieu-1619163618-8091-1619163640.jpg",
        mapLink: "https://www.google.com/maps/search/?api=1&query=21.0294,105.8355",
        content: "Chào mừng bạn đến với Văn Miếu - Quốc Tử Giám, ngôi trường đại học đầu tiên của Việt Nam.",
      ),
      // ĐỊA ĐIỂM MỚI ĐƯỢC THÊM VÀO
      POI(
        id: '4', // ID phải khác các điểm khác
        name: "Nhà thờ Đức Bà Sài Gòn",
        location: const LatLng(10.7797, 106.6994), // Tọa độ mới
        radius: 100, // Bán kính kích hoạt
        priority: 2,
        description: "Một trong những công trình kiến trúc biểu tượng của Thành phố Hồ Chí Minh, mang phong cách Roman và Gothic.",
        imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Saigon_Notre-Dame_Cathedral_2022_Facade.jpg/800px-Saigon_Notre-Dame_Cathedral_2022_Facade.jpg",
        mapLink: "https://www.google.com/maps/search/?api=1&query=10.7797,106.6994",
        content: "Chào mừng bạn đến với Nhà thờ Chính tòa Đức Bà Sài Gòn, một kiệt tác kiến trúc của Thành phố Hồ Chí Minh.",
      ),
    ];
  }
}
