import Service

struct ProductManager: ServiceType {
    static func makeService(for worker: Container) throws -> ProductManager {
        return ProductManager(container: worker)
    }
    
    let container: Container
    
    func product(for id: Item.ProductID) -> Future<Product> {
        do {
            let uri = try self.container.make(OrderService.self).productService
            return try self.container.client().get(uri + "/" + String(describing: id)).flatMap { response in
                return try response.content.decode(Product.self)
            }
        } catch let error {
            return self.container.future(error: error)
        }
    }
    
    func products(for ids: [Item.ProductID]) -> Future<[Product]> {
        return ids.map(self.product).flatten(on: self.container)
    }
    
}

extension Container {
    func product(for id: Item.ProductID) -> Future<Product> {
        do {
            return try self.make(ProductManager.self).product(for: id)
        } catch let error {
            return self.future(error: error)
        }
    }
    
    func products(for ids: [Item.ProductID]) -> Future<[Product]> {
        return ids.map(self.product).flatten(on: self)
    }
    
    func products<T>(
        for items: [Item],
        reduceInto result: T,
        _ handler: @escaping (inout T, Item, Product)throws -> ()
    ) -> Future<T> {
        return products(for: items.map { $0.productID }).map { products in
            var result = result
            try items.forEach { item in
                if let product = products.first(where: { $0.id == item.productID }) {
                    try handler(&result, item, product)
                }
            }
            return result
        }
    }
}
