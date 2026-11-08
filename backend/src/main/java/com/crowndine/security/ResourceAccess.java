package com.crowndine.security;

import com.crowndine.model.User;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;

public final class ResourceAccess {
    private ResourceAccess() {}
    public static boolean isStaff() {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.isAuthenticated() && auth.getAuthorities().stream()
                .anyMatch(a -> java.util.Set.of("ADMIN", "STAFF", "ROLE_ADMIN", "ROLE_STAFF").contains(a.getAuthority()));
    }
    public static void requireOwnerOrStaff(User owner, String username) {
        if (isStaff() || (owner != null && username != null && username.equals(owner.getUsername()))) return;
        throw new AccessDeniedException("Bạn không có quyền truy cập dữ liệu này");
    }
    public static void requireOwnerOrStaff(User owner) {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        requireOwnerOrStaff(owner, auth == null ? null : auth.getName());
    }
}
