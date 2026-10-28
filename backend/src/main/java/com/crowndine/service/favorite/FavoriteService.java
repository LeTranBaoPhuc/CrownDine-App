package com.crowndine.service.favorite;

import com.crowndine.dto.response.FavoriteResponse;

import java.util.List;

public interface FavoriteService {
    List<FavoriteResponse> getMyFavorites(String username);
    void addFavoriteItem(Long itemId, String username);
    void removeFavoriteItem(Long itemId, String username);
    void addFavoriteCombo(Long comboId, String username);
    void removeFavoriteCombo(Long comboId, String username);
    boolean isFavoriteItem(Long itemId, String username);
    boolean isFavoriteCombo(Long comboId, String username);
}
