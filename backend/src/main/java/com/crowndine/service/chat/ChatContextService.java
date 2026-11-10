package com.crowndine.service.chat;

import com.crowndine.common.enums.EItemStatus;
import com.crowndine.model.Category;
import com.crowndine.model.Combo;
import com.crowndine.model.Item;
import com.crowndine.repository.CategoryRepository;
import com.crowndine.repository.ComboRepository;
import com.crowndine.repository.ItemRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.text.DecimalFormat;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ChatContextService {

    private final ItemRepository itemRepository;
    private final ComboRepository comboRepository;
    private final CategoryRepository categoryRepository;

    /**
     * Get restaurant context information for AI
     */
    public String getRestaurantContext() {
        StringBuilder context = new StringBuilder();
        
        // Restaurant info
        context.append("THÔNG TIN NHÀ HÀNG CROWNDINE:\n");
        context.append("- Giờ mở cửa: 10:00 - 22:00 hàng ngày\n");
        context.append("- Địa chỉ: [Cập nhật địa chỉ]\n");
        context.append("- Số điện thoại: [Cập nhật số điện thoại]\n\n");
        
        DecimalFormat df = new DecimalFormat("#,###");
        
        // Categories and Menu Items
        context.append("MENU:\n");
        List<Category> categories = categoryRepository.findAll();
        List<Item> allAvailableItems = itemRepository.findAll().stream()
                .filter(item -> item.getStatus() == EItemStatus.AVAILABLE)
                .collect(Collectors.toList());
        
        // Map items by category ID for fast lookup
        Map<Long, List<Item>> itemsByCategory = allAvailableItems.stream()
                .filter(item -> item.getCategory() != null)
                .collect(Collectors.groupingBy(item -> item.getCategory().getId()));

        for (Category category : categories) {
            List<Item> items = itemsByCategory.getOrDefault(category.getId(), Collections.emptyList());
            if (items.isEmpty()) continue;

            context.append("\n").append(category.getName()).append(":\n");
            for (Item item : items) {
                context.append("  - ").append(item.getName());
                if (item.getDescription() != null && !item.getDescription().isEmpty()) {
                    context.append(" (").append(item.getDescription()).append(")");
                }
                context.append(" - Giá: ");
                if (item.getPriceAfterDiscount() != null && 
                    item.getPriceAfterDiscount().compareTo(item.getPrice()) < 0) {
                    context.append(df.format(item.getPriceAfterDiscount())).append(" VNĐ (giảm từ ")
                           .append(df.format(item.getPrice())).append(" VNĐ)");
                } else {
                    context.append(df.format(item.getPrice())).append(" VNĐ");
                }
                context.append("\n");
            }
        }
        
        // Combos
        List<Combo> combos = comboRepository.findAll();
        if (!combos.isEmpty()) {
            context.append("\nCOMBO:\n");
            for (Combo combo : combos) {
                context.append("  - ").append(combo.getName());
                if (combo.getDescription() != null && !combo.getDescription().isEmpty()) {
                    context.append(" (").append(combo.getDescription()).append(")");
                }
                context.append(" - Giá: ");
                if (combo.getPriceAfterDiscount() != null && 
                    combo.getPriceAfterDiscount().compareTo(combo.getPrice()) < 0) {
                    context.append(df.format(combo.getPriceAfterDiscount())).append(" VNĐ (giảm từ ")
                           .append(df.format(combo.getPrice())).append(" VNĐ)");
                } else {
                    context.append(df.format(combo.getPrice())).append(" VNĐ");
                }
                context.append("\n");
            }
        }
        
        context.append("\nBàn trống chỉ được xác định bằng kiểm tra ngày, giờ và số khách cụ thể.\n");
        context.append("\nLƯU Ý:\n");
        context.append("- Giá có thể thay đổi, vui lòng xác nhận khi đặt bàn\n");
        context.append("- Có thể đặt trước món khi đặt bàn\n");
        
        return context.toString();
    }

    /**
     * Search menu items by keyword
     */
    public String searchMenuItems(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return "";
        }
        
        String searchTerm = keyword.toLowerCase().trim();
        List<Item> items = itemRepository.findAll().stream()
                .filter(item -> item.getStatus() == EItemStatus.AVAILABLE &&
                        (item.getName().toLowerCase().contains(searchTerm) ||
                         (item.getDescription() != null && item.getDescription().toLowerCase().contains(searchTerm))))
                .limit(10)
                .collect(Collectors.toList());
        
        if (items.isEmpty()) {
            return "Không tìm thấy món nào với từ khóa \"" + keyword + "\"";
        }
        
        DecimalFormat df = new DecimalFormat("#,###");
        StringBuilder result = new StringBuilder("Kết quả tìm kiếm cho \"" + keyword + "\":\n");
        for (Item item : items) {
            result.append("  - ").append(item.getName());
            if (item.getDescription() != null) {
                result.append(" (").append(item.getDescription()).append(")");
            }
            result.append(" - Giá: ").append(df.format(item.getPrice())).append(" VNĐ\n");
        }
        
        return result.toString();
    }
}