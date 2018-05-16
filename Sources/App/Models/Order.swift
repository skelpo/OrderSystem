import FluentMySQL
import Vapor

final class Order: Content, MySQLModel, Migration {
    var id: Int?
    
    var userID: Int?
    var comment: String?
    var status: Order.Status
    var paymentStatus: Order.PaymentStatus
    var paidTotal: Int
    var refundedTotal: Int
    
    init(from decoder: Decoder)throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.userID = try container.decodeIfPresent(Int.self, forKey: .userID)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        self.status = try container.decode(Order.Status.self, forKey: .status)
        self.paymentStatus = try container.decode(Order.PaymentStatus.self, forKey: .paymentStatus)
        self.paidTotal = try container.decode(Int.self, forKey: .paidTotal)
        self.refundedTotal = try container.decode(Int.self, forKey: .refundedTotal)
    }
    
    var guest: Bool { return self.userID == nil }
    
    func total(with executor: DatabaseConnectable) -> Future<Int> {
        return Future.flatMap(on: executor) {
            return try Item.query(on: executor).join(field: \OrderItem.itemID).filter(OrderItem.self, \.orderID == self.requireID()).sum(\.total)
        }.map(to: Int.self) { Int($0) }
    }
    
    func tax(with executor: DatabaseConnectable) -> Future<Int> {
        return Future.flatMap(on: executor) {
            return try Item.query(on: executor).join(field: \OrderItem.itemID).filter(OrderItem.self, \.orderID == self.requireID()).sum(\.tax)
        }.map(to: Int.self) { Int($0) }
    }
}
