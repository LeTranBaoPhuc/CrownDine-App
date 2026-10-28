package com.crowndine.service.impl.favorite;

import com.crowndine.dto.response.FavoriteResponse;
import com.crowndine.exception.ResourceNotFoundException;
import com.crowndine.model.Combo;
import com.crowndine.model.Favorite;
import com.crowndine.model.Item;
import com.crowndine.model.User;
import com.crowndine.repository.ComboRepository;
import com.crowndine.repository.FavoriteRepository;
import com.crowndine.repository.ItemRepository;
import com.crowndine.repository.UserRepository;
import com.crowndine.service.favorite.FavoriteService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j(topic = "FAVORITE-SERVICE")
public class FavoriteServiceImpl implements FavoriteService {

    private final FavoriteRepository favoriteRepository;
    private final UserRepository userRepository;
    private final ItemRepository itemRepository;
    private final ComboRepository comboRepository;

    @Override
    public List<FavoriteResponse> getMyFavorites(String username) {
        User user = getUser(username);
        return favoriteRepository.findAllByUser(user)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    @Transactional
    public void addFavoriteItem(Long itemId, String username) {
        User user = getUser(username);
        Item item = itemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Item not found: " + itemId));

        if (!favoriteRepository.existsByUserAndItem(user, item)) {
            Favorite favorite = Favorite.builder()
                    .user(user)
                    .item(item)
                    .build();
            favoriteRepository.save(favorite);
        }
    }

    @Override
    @Transactional
    public void removeFavoriteItem(Long itemId, String username) {
        User user = getUser(username);
        Item item = itemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Item not found: " + itemId));

        favoriteRepository.findByUserAndItem(user, item)
                .ifPresent(favoriteRepository::delete);
    }

    @Override
    @Transactional
    public void addFavoriteCombo(Long comboId, String username) {
        User user = getUser(username);
        Combo combo = comboRepository.findById(comboId)
                .orElseThrow(() -> new ResourceNotFoundException("Combo not found: " + comboId));

        if (!favoriteRepository.existsByUserAndCombo(user, combo)) {
            Favorite favorite = Favorite.builder()
                    .user(user)
                    .combo(combo)
                    .build();
            favoriteRepository.save(favorite);
        }
    }

    @Override
    @Transactional
    public void removeFavoriteCombo(Long comboId, String username) {
        User user = getUser(username);
        Combo combo = comboRepository.findById(comboId)
                .orElseThrow(() -> new ResourceNotFoundException("Combo not found: " + comboId));

        favoriteRepository.findByUserAndCombo(user, combo)
                .ifPresent(favoriteRepository::delete);
    }

    @Override
    public boolean isFavoriteItem(Long itemId, String username) {
        User user = getUser(username);
        Item item = itemRepository.findById(itemId).orElse(null);
        return item != null && favoriteRepository.existsByUserAndItem(user, item);
    }

    @Override
    public boolean isFavoriteCombo(Long comboId, String username) {
        User user = getUser(username);
        Combo combo = comboRepository.findById(comboId).orElse(null);
        return combo != null && favoriteRepository.existsByUserAndCombo(user, combo);
    }

    private User getUser(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + username));
    }

    private FavoriteResponse toResponse(Favorite favorite) {
        FavoriteResponse.FavoriteResponseBuilder builder = FavoriteResponse.builder()
                .id(favorite.getId())
                .createdAt(favorite.getCreatedAt());

        if (favorite.getItem() != null) {
            Item item = favorite.getItem();
            builder.itemId(item.getId())
                    .itemName(item.getName())
                    .itemImageUrl(item.getImageUrl())
                    .itemPrice(item.getPrice());
        }

        if (favorite.getCombo() != null) {
            Combo combo = favorite.getCombo();
            builder.comboId(combo.getId())
                    .comboName(combo.getName())
                    .comboImageUrl(combo.getImageUrl())
                    .comboPrice(combo.getPrice());
        }

        return builder.build();
    }
}
