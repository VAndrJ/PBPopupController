//
//  UIViewController+Private.swift
//  PBPopupController
//
//  Created by Patrick BODET on 15/04/2018.
//  Copyright © 2018-2022 Patrick BODET. All rights reserved.
//

import Foundation
import UIKit
import ObjectiveC

//_setContentOverlayInsets:
private let sCoOvBase64 = "X3NldENvbnRlbnRPdmVybGF5SW5zZXRzOg=="
//_updateContentOverlayInsetsFromParentIfNecessary
private let uCOIFPINBase64 = "X3VwZGF0ZUNvbnRlbnRPdmVybGF5SW5zZXRzRnJvbVBhcmVudElmTmVjZXNzYXJ5"
//_hideBarWithTransition:isExplicit:
private let hBWTiEBase64 = "X2hpZGVCYXJXaXRoVHJhbnNpdGlvbjppc0V4cGxpY2l0Og=="
//_showBarWithTransition:isExplicit:
private let sBWTiEBase64 = "X3Nob3dCYXJXaXRoVHJhbnNpdGlvbjppc0V4cGxpY2l0Og=="
//_setToolbarHidden:edge:duration:
private let sTHedBase64 = "X3NldFRvb2xiYXJIaWRkZW46ZWRnZTpkdXJhdGlvbjo="
//hideBarWithTransition:
private let hBWTBase64 = "aGlkZUJhcldpdGhUcmFuc2l0aW9uOg=="
//showBarWithTransition:
private let sBWTBase64 = "c2hvd0JhcldpdGhUcmFuc2l0aW9uOg=="
//_viewSafeAreaInsetsFromScene
private let vSAIFSBase64 = "X3ZpZXdTYWZlQXJlYUluc2V0c0Zyb21TY2VuZQ=="

public extension UITabBarController
{
    private static let swizzleImplementation: Void = {
        let instance = UITabBarController.self()
        
        let aClass: AnyClass! = object_getClass(instance)
        
        var originalMethod: Method!
        var swizzledMethod: Method!
        
        originalMethod = class_getInstanceMethod(aClass, #selector(setViewControllers(_ :animated:)))
        swizzledMethod = class_getInstanceMethod(aClass, #selector(pb_setViewControllers(_ :animated:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        //_hideBarWithTransition:isExplicit:
        var selName = _PBPopupDecodeBase64String(base64String: hBWTiEBase64)!
        var selector = NSSelectorFromString(selName)
        originalMethod = class_getInstanceMethod(aClass, selector)
        swizzledMethod = class_getInstanceMethod(aClass, #selector(_hBWT(t:iE:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        //_showBarWithTransition:isExplicit:
        selName = _PBPopupDecodeBase64String(base64String: sBWTiEBase64)!
        selector = NSSelectorFromString(selName)
        originalMethod = class_getInstanceMethod(aClass, selector)
        swizzledMethod = class_getInstanceMethod(aClass, #selector(_sBWT(t:iE:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()
    
    /**
     :nodoc:
     */
    @objc static func tbc_swizzle()
    {
        _ = self.swizzleImplementation
    }
    
    //_hideBarWithTransition:isExplicit:
    @objc private func _hBWT(t: Int, iE: Bool)
    {
        self.isTabBarHiddenDuringTransition = true
        
        self._hBWT(t: t, iE: iE)
        
        if (t > 0) {
            if let _ = objc_getAssociatedObject(self, &AssociatedKeys.popupBar) as? PBPopupBar {
                if self.popupController.popupPresentationState != .hidden {
                    var duration: TimeInterval = 0.35
                    if let coordinator = self.selectedViewController?.transitionCoordinator {
                        duration = coordinator.transitionDuration
                    }
                    
                    self.bottomBar.isHidden = true
                    
                    if self.popupBarIsHidden == false {
                        UIView.animate(withDuration: duration) {
                            self.popupController.popupBarView.frame = self.popupController.popupBarViewFrameForPopupStateClosed()
                        }
                    }
                }
            }
        }
    }
    
    //_showBarWithTransition:isExplicit:
    @objc private func _sBWT(t: Int, iE: Bool)
    {
        self.isTabBarHiddenDuringTransition = false
        
        self._sBWT(t: t, iE: iE)
        
        if (t > 0) {
            if let rv = objc_getAssociatedObject(self, &AssociatedKeys.popupBar) as? PBPopupBar {
                if self.popupController.popupPresentationState != .hidden {
                    self.selectedViewController?.transitionCoordinator?.animate(alongsideTransition: { (_ context) in
                        self.popupController.popupBarView.frame = self.popupController.popupBarViewFrameForPopupStateClosed()
                        if self.popupBarWasHidden {
                            self.popupController.fixInsetsForContainerIfNeeded(addInsets: true, layout: false)
                        }
                        rv.layoutIfNeeded()
                    }, completion: { (_ context) in
                        if context.isCancelled {
                            self.isTabBarHiddenDuringTransition = true
                            
                            if !self.popupBarWasHidden {
                                UIView.animate(withDuration: 0.15) {
                                    self.popupController.popupBarView.frame = self.popupController.popupBarViewFrameForPopupStateClosed()
                                    rv.layoutIfNeeded()
                                }
                            }
                            
                            if self.popupBarWasHidden {
                                self.popupController.fixInsetsForContainerIfNeeded(addInsets: false, layout: true)
                            }
                        }
                        self.bottomBar.isHidden = context.isCancelled ? true : false
                    })
                }
            }
        }
    }
    
    @objc private func pb_setViewControllers(_ viewControllers: [UIViewController], animated: Bool)
    {
        self.pb_setViewControllers(viewControllers, animated: animated)
        
        for obj in viewControllers {
            let additionalInsets = self.popupAdditionalSafeAreaInsets
            if obj.popupAdditionalSafeAreaInsets == .zero {
                PBPopupFixInsetsForViewController(self, false, additionalInsets)
            }
        }
    }
}

internal extension UITabBarController
{
    @objc override func _animateBottomBarToHidden( _ hidden: Bool)
    {
        let height = self.tabBar.frame.height
        if height > 0.0 {
            if hidden == false {
                self.tabBar.frame.origin.y = self.view.bounds.height - height
            }
            else {
                self.tabBar.frame.origin.y = self.view.bounds.height
            }
        }
    }
    
    @objc override func _setBottomBarPosition( _ position: CGFloat)
    {
        let height = self.tabBar.frame.height
        if height > 0.0 {
            self.tabBar.frame.origin.y = position
        }
    }
    
    @objc override func insetsForBottomBar() -> UIEdgeInsets
    {
        if let bottomBarInsets = self.popupController.dataSource?.popupController?(self.popupController, insetsFor: self.bottomBar) {
            return bottomBarInsets
        }
        if let dropShadowView = self.popupController.dropShadowViewFor(self.view) {
            if dropShadowView.frame.minX > 0 {
                return UIEdgeInsets.zero
            }
        }
        return self.tabBar.isHidden == false ? UIEdgeInsets.zero : self.view.window?.safeAreaInsets ?? UIEdgeInsets.zero
    }
    
    @objc override func defaultFrameForBottomBar() -> CGRect
    {
        var bottomBarFrame = self.tabBar.frame
        let bottomBarSizeThatFits = self.tabBar.sizeThatFits(CGSize.zero)
        
        bottomBarFrame.size.height = max(bottomBarFrame.size.height, bottomBarSizeThatFits.height)
        
        bottomBarFrame.origin = CGPoint(x: 0, y: self.view.bounds.size.height - (self.isTabBarHiddenDuringTransition ? 0.0 : bottomBarFrame.size.height))
        
        return bottomBarFrame
    }
    
    @objc override func configureScrollEdgeAppearanceForBottomBar() {
#if targetEnvironment(macCatalyst)
        return
#else
        if #available(iOS 15.0, *) {
            if self.popupBar.inheritsVisualStyleFromBottomBar == false {
                return
            }
            
            if self.popupController.popupPresentationState == .presenting {
                self.tabBar.scrollEdgeAppearance = self.tabBar.standardAppearance
            }
            else {
                self.tabBar.scrollEdgeAppearance = nil
            }
        }
#endif
    }
    
    @objc override func configurePopupBarFromBottomBar()
    {
        if self.popupBar.inheritsVisualStyleFromBottomBar == false {
            return
        }
        self.popupBar.barStyle = self.tabBar.barStyle
        self.popupBar.tintColor = self.tabBar.tintColor
        self.popupBar.barTintColor = self.tabBar.barTintColor
        self.popupBar.backgroundColor = self.tabBar.backgroundColor
        self.popupBar.isTranslucent = self.tabBar.isTranslucent
    }
}

public extension UINavigationController
{
    private static let swizzleImplementation: Void = {
        let instance = UINavigationController.self()
        
        let aClass: AnyClass! = object_getClass(instance)
        
        var originalMethod: Method!
        var swizzledMethod: Method!
        
        originalMethod = class_getInstanceMethod(aClass, #selector(pushViewController(_ :animated:)))
        swizzledMethod = class_getInstanceMethod(aClass, #selector(pb_pushViewController(_ :animated:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        originalMethod = class_getInstanceMethod(aClass, #selector(popViewController(animated:)))
        swizzledMethod = class_getInstanceMethod(aClass, #selector(pb_popViewController(animated:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        originalMethod = class_getInstanceMethod(aClass, #selector(popToViewController(_ :animated:)))
        swizzledMethod = class_getInstanceMethod(aClass, #selector(pb_popToViewController(_ :animated:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        originalMethod = class_getInstanceMethod(aClass, #selector(popToRootViewController(animated:)))
        swizzledMethod = class_getInstanceMethod(aClass, #selector(pb_popToRootViewController(animated:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }

        originalMethod = class_getInstanceMethod(aClass, #selector(setViewControllers(_ :animated:)))
        swizzledMethod = class_getInstanceMethod(aClass, #selector(pb_setViewControllers(_ :animated:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        //_setToolbarHidden:edge:duration:
        var selName = _PBPopupDecodeBase64String(base64String: sTHedBase64)!
        var selector = NSSelectorFromString(selName)
        originalMethod = class_getInstanceMethod(aClass, selector)
        swizzledMethod = class_getInstanceMethod(aClass, #selector(_sTH(h:e:d:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()
    
    /**
     :nodoc:
     */
    @objc static func nc_swizzle()
    {
        _ = self.swizzleImplementation
    }
    
    //_setToolbarHidden:edge:duration:
    @objc private func _sTH(h: Bool, e: UInt, d: CGFloat)
    {
        if let rv = objc_getAssociatedObject(self, &AssociatedKeys.popupBar) as? PBPopupBar {
            if self.popupController.popupPresentationState != .hidden {
                if self.popupBarIsHidden == true {
                    self.popupController.popupBarView.frame = self.popupController.popupBarViewFrameForPopupStateHidden()
                }
                else {
                    self.popupController.popupBarView.frame = self.popupController.popupBarViewFrameForPopupStateClosed()
                }
                self._sTH(h: h, e: e, d: d)
                self.bottomBar.isHidden = h
                    if let coordinator = self.transitionCoordinator {
                        coordinator.animate(alongsideTransition: { (_ context) in
                            self.popupController.popupBarView.frame = self.popupController.popupBarViewFrameForPopupStateClosed()
                            if self.popupBarWasHidden {
                                self.popupController.fixInsetsForContainerIfNeeded(addInsets: true, layout: false)
                            }
                            rv.layoutIfNeeded()
                        }) { (_ context) in
                            if context.isCancelled {
                                if self.popupBarWasHidden {
                                    self.popupBarIsHidden = true
                                    self.popupController.popupBarView.frame = self.popupController.popupBarViewFrameForPopupStateHidden()
                                    self.popupController.fixInsetsForContainerIfNeeded(addInsets: false, layout: false)
                                    rv.layoutIfNeeded()
                                }
                            }
                        }
                    }
                    else {
                        UIView.animate(withDuration: d) {
                            self.popupController.popupBarView.frame = self.popupController.popupBarViewFrameForPopupStateClosed()
                            if self.popupBarWasHidden {
                                self.popupController.fixInsetsForContainerIfNeeded(addInsets: true, layout: false)
                            }
                            rv.layoutIfNeeded()
                        }
                    }
            }
            else {
                self._sTH(h: h, e: e, d: d)
                self.bottomBar.isHidden = h
                rv.layoutIfNeeded()
            }
        }
        else {
            self._sTH(h: h, e: e, d: d)
            //self.toolbar.isHidden = h
        }
    }
    
    @objc private func pb_pushViewController(_ viewController: UIViewController, animated: Bool)
    {
        if let popupController = self.popupControllerFor(self) {
            if let vc = popupController.containerViewController {
                if self.popupBarFor(vc) != nil, popupController.popupPresentationState == .closed {
                    //vc.popupBarIsHidden = false
                    vc.popupBarWasHidden = false
                    if viewController.hidesPopupBarWhenPushed || vc.popupBarIsHidden {
                        viewController.hidesPopupBarWhenPushed = true
                        vc.popupBarIsHidden = true
                        vc.hidePopupBar(animated: false, completion: nil)
                    }
                }
            }
        }
        if let rv = objc_getAssociatedObject(self, &AssociatedKeys.popupBar) as? PBPopupBar, !rv.isHidden {
            let additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.topViewController?.additionalSafeAreaInsets.bottom ?? 0.0, right: 0)
            if viewController.popupAdditionalSafeAreaInsets == .zero {
                PBPopupFixInsetsForViewController(viewController, false, additionalInsets)
            }
        }
        self.pb_pushViewController(viewController, animated: animated)
    }
    
    @objc private func pb_popViewController(animated: Bool) -> UIViewController?
    {
        if let top = self.topViewController, top.hidesPopupBarWhenPushed {
            if let popupController = self.popupControllerFor(self) {
                if let vc = popupController.containerViewController {
                    if self.popupBarFor(vc) != nil, vc.popupBarIsHidden == true {
                        let back = self.viewControllers[self.viewControllers.count - 2] as UIViewController
                        if back.hidesPopupBarWhenPushed == false {
                            vc.popupBarWasHidden = true
                            vc.popupBarIsHidden = false
                            if let nc = vc as? UINavigationController, nc.isToolbarHidden {
                                if let top = self.pb_popViewController(animated: animated), top.transitionCoordinator != nil {
                                    self.startInteractivePopupBarTransition(fromViewController: top)
                                    return top
                                }
                            }
                        }
                    }
                }
            }
        }
        return self.pb_popViewController(animated: animated)
    }
    
    @objc private func pb_popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]?
    {
        if let top = self.topViewController, top.hidesPopupBarWhenPushed {
            if let popupController = self.popupControllerFor(self) {
                if let vc = popupController.containerViewController {
                    if self.popupBarFor(vc) != nil, vc.popupBarIsHidden == true {
                        if viewController.hidesPopupBarWhenPushed == false {
                            vc.popupBarWasHidden = true
                            vc.popupBarIsHidden = false
                            if let nc = vc as? UINavigationController, nc.isToolbarHidden {
                                if let viewControllers = self.pb_popToViewController(viewController, animated: animated), vc.transitionCoordinator != nil {
                                    self.startInteractivePopupBarTransition(fromViewController: top)
                                    return viewControllers
                                }
                            }
                        }
                    }
                }
            }
        }
        return self.pb_popToViewController(viewController, animated: animated)
    }
    
    @objc private func pb_popToRootViewController(animated: Bool) -> [UIViewController]?
    {
        if let top = self.topViewController, top.hidesPopupBarWhenPushed {
            if let popupController = self.popupControllerFor(self) {
                if let vc = popupController.containerViewController {
                    if self.popupBarFor(vc) != nil, vc.popupBarIsHidden == true {
                        let back = self.viewControllers[0] as UIViewController
                        if back.hidesPopupBarWhenPushed == false {
                            vc.popupBarWasHidden = true
                            vc.popupBarIsHidden = false
                            if let nc = vc as? UINavigationController, nc.isToolbarHidden {
                                if let viewControllers = self.pb_popToRootViewController(animated: animated), vc.transitionCoordinator != nil {
                                    self.startInteractivePopupBarTransition(fromViewController: top)
                                    return viewControllers
                                }
                            }
                        }
                    }
                }
            }
        }
        return self.pb_popToRootViewController(animated: animated)
    }
    
    @objc private func pb_setViewControllers(_ viewControllers: [UIViewController], animated: Bool)
    {
        self.pb_setViewControllers(viewControllers, animated: animated)
        for obj in viewControllers {
            let additionalInsets = self.popupAdditionalSafeAreaInsets
            if obj.popupAdditionalSafeAreaInsets == .zero {
                PBPopupFixInsetsForViewController(self, false, additionalInsets)
            }
        }
    }
    
    private func startInteractivePopupBarTransition(fromViewController: UIViewController)
    {
        guard let popupController = self.popupControllerFor(self), let vc = popupController.containerViewController else {
            return
        }
        if let coordinator = fromViewController.transitionCoordinator {
            coordinator.animate { context in
                popupController.popupBarView.frame = popupController.popupBarViewFrameForPopupStateClosed()
                if vc.popupBarWasHidden {
                    popupController.fixInsetsForContainerIfNeeded(addInsets: true, layout: false)
                }
            } completion: { context in
                if context.isCancelled {
                    if vc.popupBarWasHidden {
                        vc.popupBarIsHidden = true
                        popupController.popupBarView.frame = popupController.popupBarViewFrameForPopupStateHidden()
                        popupController.fixInsetsForContainerIfNeeded(addInsets: false, layout: false)
                    }
                }
            }
        }
    }
    
    private func popupControllerFor(_ controller: UIViewController) -> PBPopupController?
    {
        if let rv = (objc_getAssociatedObject(controller, &AssociatedKeys.popupController) as? PBPopupController) {
            return rv
        }
        if  controller.parent == nil {
            return nil
        }
        return popupControllerFor(controller.parent!)
    }
    
    private func popupBarFor(_ controller: UIViewController) -> PBPopupBar?
    {
        if let rv = objc_getAssociatedObject(controller, &AssociatedKeys.popupBar) as? PBPopupBar {
            return rv
        }
        return nil
    }
}

internal extension UINavigationController
{
    @objc override func _animateBottomBarToHidden( _ hidden: Bool)
    {
        var height = self.toolbar.frame.height
        if let tabBarController = self.tabBarController {
            height += tabBarController.defaultFrameForBottomBar().height
        }
        
        // FIXME: iOS 14 beta 6 bug (frame animation fails)
        //let insets = self.insetsForBottomBar()
        
        if height > 0.0 {
            if hidden == false {
                //self.toolbar.frame.origin.y = self.view.bounds.height - height - insets.bottom
                self.toolbar.transform = .identity
            }
            else {
                //self.toolbar.frame.origin.y = self.view.bounds.height
                let fromY = self.toolbar.frame.minY
                let toY = self.view.bounds.height
                self.toolbar.transform = self.toolbar.transform.translatedBy(x: 0, y: toY - fromY)
            }
            
            if let tabBarController = self.tabBarController {
                tabBarController._animateBottomBarToHidden(hidden)
            }
        }
    }
    
    @objc override func _setBottomBarPosition( _ position: CGFloat)
    {
        let height = self.toolbar.frame.height
        if height > 0.0 {
            self.toolbar.frame.origin.y = position
        }
    }
    
    @objc override func insetsForBottomBar() -> UIEdgeInsets
    {
        if let tabBarController = self.tabBarController, tabBarController.isTabBarHiddenDuringTransition == false {
            return tabBarController.insetsForBottomBar()
        }
        if let dropShadowView = self.popupController.dropShadowViewFor(self.view) {
            if dropShadowView.frame.minX > 0 {
                return UIEdgeInsets.zero
            }
        }
        return self.view.window?.safeAreaInsets ?? UIEdgeInsets.zero
    }
    
    @objc override func defaultFrameForBottomBar() -> CGRect
    {
        var toolBarFrame = self.toolbar.frame
        
        toolBarFrame.origin = CGPoint(x: 0, y: self.view.bounds.height - (self.isToolbarHidden ? 0.0 : toolBarFrame.size.height))
        toolBarFrame.size.height = self.isToolbarHidden ? 0.0 : toolBarFrame.size.height
        
        if let tabBarController = self.tabBarController {
            let tabBarFrame = tabBarController.defaultFrameForBottomBar()
            toolBarFrame.origin.y -= tabBarController.isTabBarHiddenDuringTransition ? 0.0 : tabBarFrame.height
        }
        
        return toolBarFrame
    }
    
    @objc override func configureScrollEdgeAppearanceForBottomBar()
    {
#if targetEnvironment(macCatalyst)
#else
        if #available(iOS 15.0, *) {
            if self.popupBar.inheritsVisualStyleFromBottomBar == false {
                return
            }
            
            if self.popupController.popupPresentationState == .presenting {
                self.toolbar.scrollEdgeAppearance = self.toolbar.standardAppearance
            }
            else {
                self.toolbar.scrollEdgeAppearance = nil
            }
        }
#endif
    }
    
    @objc override func configurePopupBarFromBottomBar()
    {
        if self.popupBar.inheritsVisualStyleFromBottomBar == false {
            return
        }
        self.popupBar.barStyle = self.navigationBar.barStyle
        self.popupBar.tintColor = self.navigationBar.tintColor
        self.popupBar.barTintColor = self.navigationBar.barTintColor
        self.popupBar.backgroundColor = self.navigationBar.backgroundColor
        self.popupBar.isTranslucent = self.navigationBar.isTranslucent
    }
}

public extension UIViewController
{
    private static let swizzleImplementation: Void = {
        let instance = UIViewController.self()
        
        let aClass: AnyClass! = object_getClass(instance)
        
        var originalMethod: Method!
        var swizzledMethod: Method!
        
        #if !targetEnvironment(macCatalyst)
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 11 {
            //_setContentOverlayInsets:
            var selName = _PBPopupDecodeBase64String(base64String: sCoOvBase64)!
            var selector = NSSelectorFromString(selName)
            originalMethod = class_getInstanceMethod(aClass, selector)
            swizzledMethod = class_getInstanceMethod(aClass, #selector(_sCoOvIns(insets:)))
            if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
        else {
            //_updateContentOverlayInsetsFromParentIfNecessary
            var selName = _PBPopupDecodeBase64String(base64String: uCOIFPINBase64)!
            var selector = NSSelectorFromString(selName)
            originalMethod = class_getInstanceMethod(aClass, selector)
            swizzledMethod = class_getInstanceMethod(aClass, #selector(_uCOIFPIN))
            if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
        //_viewSafeAreaInsetsFromScene
        var selName = _PBPopupDecodeBase64String(base64String: vSAIFSBase64)!
        var selector = NSSelectorFromString(selName)
        originalMethod = class_getInstanceMethod(aClass, selector)
        swizzledMethod = class_getInstanceMethod(aClass, #selector(_vSAIFS))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        #else
        var selName = _PBPopupDecodeBase64String(base64String: uCOIFPINBase64)!
        var selector = NSSelectorFromString(selName)
        originalMethod = class_getInstanceMethod(aClass, selector)
        swizzledMethod = class_getInstanceMethod(aClass, #selector(_uCOIFPIN))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        #endif
        
        originalMethod = class_getInstanceMethod(aClass, #selector(addChild(_:)))
        swizzledMethod = class_getInstanceMethod(aClass, #selector(pb_addChild(_ :)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        originalMethod = class_getInstanceMethod(aClass, #selector(viewWillTransition(to:with:)))
        swizzledMethod = class_getInstanceMethod(aClass, #selector(pb_viewWillTransition(to:with:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()
    
    /**
     :nodoc:
     */
    @objc static func vc_swizzle()
    {
        _ = self.swizzleImplementation
    }
    
    //_setContentOverlayInsets:
    @objc private func _sCoOvIns(insets: UIEdgeInsets)
    {
        var newInsets = insets
        newInsets.bottom += self.additionalSafeAreaInsetsBottomForContainer
        if let rv = objc_getAssociatedObject(self, &AssociatedKeys.popupBar) as? PBPopupBar {
            if !(rv.isHidden) && self.popupController.popupPresentationState != .dismissing {
                newInsets.bottom += rv.frame.height
                self._sCoOvIns(insets:newInsets)
            }
            else {
                self._sCoOvIns(insets:newInsets)
            }
        }
        else {
            self._sCoOvIns(insets:newInsets)
        }
    }
    
    //_updateContentOverlayInsetsFromParentIfNecessary
    @objc private func _uCOIFPIN()
    {
        self._uCOIFPIN()
    }
    
    //_viewSafeAreaInsetsFromScene
    @objc private func _vSAIFS() -> UIEdgeInsets
    {
        /// Find the popup content view safe area insets
        if let vc = self.popupContainerViewController, let popupContentView = vc.popupContentView {
            var insets = popupContentView.superview!.safeAreaInsets
            let containerInsets = vc.view.safeAreaInsets
            if let svc = vc.splitViewController, containerInsets.left > 0 {
                if UIDevice.current.userInterfaceIdiom == .phone || (UIDevice.current.userInterfaceIdiom == .pad && vc.popupController.dropShadowViewFor(svc.view) == nil) {
                    insets.left = containerInsets.left
                }
            }
            if popupContentView.popupPresentationStyle == .deck  || popupContentView.popupPresentationStyle == .custom {
                insets.top = 0
            }
            return insets
        }
        let insets = self._vSAIFS()
        return insets
    }
    
    internal func pb_popupController() -> PBPopupController!
    {
        let rv = PBPopupController(containerViewController: self)
        self.popupController = rv
        return rv
    }
    
    @objc private func pb_addChild(_ viewController: UIViewController)
    {
        self.pb_addChild(viewController)
        
        if self.additionalSafeAreaInsetsBottomForContainer > 0 {
            let additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.additionalSafeAreaInsetsBottomForContainer, right: 0)
            PBPopupFixInsetsForViewController(self, false, additionalInsets)
        }
        
        if let svc = self as? UISplitViewController {
            if let vc1 = svc.children.first, let rv = objc_getAssociatedObject(vc1, &AssociatedKeys.popupBar) as? PBPopupBar, !rv.isHidden {
                var additionalInsets: UIEdgeInsets
                if let nc = vc1 as? UINavigationController {
                    additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: -nc.topViewController!.additionalSafeAreaInsets.bottom, right: 0)
                }
                else {
                    additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: -viewController.additionalSafeAreaInsets.bottom, right: 0)
                }
                PBPopupFixInsetsForViewController(viewController, false, additionalInsets)
            }
            else {
                if let vc1 = svc.children.first {
                    let additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: vc1.additionalSafeAreaInsets.bottom, right: 0)
                    PBPopupFixInsetsForViewController(viewController, false, additionalInsets)
                }
            }
        }
    }
    
    private func viewWillTransitionToSize(_ size: CGSize,  with coordinator: UIViewControllerTransitionCoordinator)
    {
            if self.popupController.popupPresentationState != .dismissing {
                self.popupController.popupBarView.frame = self.popupController.popupPresentationState == .hidden ? self.popupController.popupBarViewFrameForPopupStateHidden() :  self.popupController.popupBarViewFrameForPopupStateClosed()
            }
            
            if self.popupController.popupPresentationState == .closed {
                self.popupContentView.frame = self.popupController.popupBarViewFrameForPopupStateClosed()
                self.popupContentViewController.view.frame.origin = self.popupContentView.frame.origin
                self.popupContentViewController.view.frame.size = CGSize(width: self.popupContentView.frame.size.width, height: self.view.frame.height)
            }
            
            //rv.setNeedsUpdateConstraints()
            //rv.setNeedsLayout()
            //rv.layoutIfNeeded()
    }
    
    @objc private func pb_viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        self.pb_viewWillTransition(to: size, with: coordinator)

        if (objc_getAssociatedObject(self, &AssociatedKeys.popupBar) as? PBPopupBar) != nil {
            coordinator.animate(alongsideTransition: {(_ context: UIViewControllerTransitionCoordinatorContext) -> Void in
                self.viewWillTransitionToSize(size, with: coordinator)
            }, completion: {(_ context: UIViewControllerTransitionCoordinatorContext) -> Void in
                self.viewWillTransitionToSize(size, with: coordinator)
            })
        }
    }
    
    internal func _cleanupPopup()
    {
        PBLog("_cleanupPopup")
        objc_setAssociatedObject(self, &AssociatedKeys.popupContentViewController, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &AssociatedKeys.popupContentView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &AssociatedKeys.bottomBar, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &AssociatedKeys.popupBar, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &AssociatedKeys.popupController, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &AssociatedKeys.popupContainerViewController, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

internal extension UIViewController
{
    @objc func _animateBottomBarToHidden( _ hidden: Bool)
    {
        let height = self.popupController.bottomBarHeight
        
        // FIXME: iOS 14 beta 6 bug (toolbar frame animation fails)
        //let insets = self.insetsForBottomBar()
        
        if height > 0.0 {
            if hidden == false {
                //self.bottomBar.frame.origin.y = self.view.bounds.height - height - insets.bottom
                self.bottomBar.transform = .identity
            }
            else {
                self.bottomBar.transform = .identity
                //self.bottomBar.frame.origin.y = self.view.bounds.height
                let fromY = self.bottomBar.frame.minY
                let toY = self.view.bounds.height
                self.bottomBar.transform = self.bottomBar.transform.translatedBy(x: 0, y: toY - fromY)
            }
        }
    }
    
    @objc func _setBottomBarPosition( _ position: CGFloat)
    {
        let height = self.popupController.bottomBarHeight
        if height > 0.0 {
            self.bottomBar.frame.origin.y = position
        }
    }
    
    @objc func insetsForBottomBar() -> UIEdgeInsets
    {
        var insets: UIEdgeInsets = .zero
        if let dropShadowView = self.popupController.dropShadowViewFor(self.view) {
            if dropShadowView.frame.minX > 0 {
                return UIEdgeInsets.zero
            }
        }
        insets = self.view.window?.safeAreaInsets ?? UIEdgeInsets.zero
        if self.popupController.dataSource?.bottomBarView?(for: self.popupController) != nil {
            if let bottomBarInsets = self.popupController.dataSource?.popupController?(self.popupController, insetsFor: self.bottomBar) {
                insets = bottomBarInsets
            }
        }
        return insets
    }
    
    @objc func defaultFrameForBottomBar() -> CGRect
    {
        var bottomBarFrame = CGRect(x: 0.0, y: self.view.bounds.size.height, width: self.view.bounds.size.width, height: 0.0)
        if let bottomBarView = self.popupController.dataSource?.bottomBarView?(for: self.popupController) {
            if let defaultFrame = self.popupController.dataSource?.popupController?(self.popupController, defaultFrameFor: self.bottomBar) {
                return defaultFrame
            }
            else {
                bottomBarFrame = bottomBarView.frame
            }
        }
        bottomBarFrame.origin = CGPoint(x: bottomBarFrame.origin.x, y: self.view.bounds.height - (self.bottomBar.isHidden ? 0.0 : bottomBarFrame.size.height))
        return bottomBarFrame
    }
    
    @objc func configureScrollEdgeAppearanceForBottomBar() {
        // Do nothing for UIView
    }
    
    @objc func configurePopupBarFromBottomBar()
    {
        if self.popupBar.inheritsVisualStyleFromBottomBar == false {
            return
        }
        self.popupBar.tintColor = self.view.tintColor
        self.popupBar.backgroundColor = self.view.backgroundColor
    }
}

/*
@inline(__always) func PBPopupFixInsetsForViewController(_ controller: UIViewController, _ layout: Bool, _ additionalSafeAreaInsets: UIEdgeInsets)
{
    if (controller is UITabBarController) || (controller is UINavigationController) || (controller.children.count > 0 && !(controller is UISplitViewController)) {
        for (_, obj) in controller.children.enumerated() {
            let oldInsets = obj.popupAdditionalSafeAreaInsets
            var insets = oldInsets
            if oldInsets.top != additionalSafeAreaInsets.top {
                insets.top += additionalSafeAreaInsets.top
            }
            if oldInsets.bottom != additionalSafeAreaInsets.bottom {
                insets.bottom += additionalSafeAreaInsets.bottom
            }
            if oldInsets != insets {
                obj.additionalSafeAreaInsets = insets
                controller.popupAdditionalSafeAreaInsets = insets
                obj.popupAdditionalSafeAreaInsets = insets
            }
        }
    } else {
        let oldInsets = controller.popupAdditionalSafeAreaInsets
        var insets = oldInsets
        if oldInsets.top != additionalSafeAreaInsets.top {
            insets.top += additionalSafeAreaInsets.top
        }
        if oldInsets.bottom != additionalSafeAreaInsets.bottom {
            insets.bottom += additionalSafeAreaInsets.bottom
        }
        if oldInsets != insets {
            controller.additionalSafeAreaInsets = insets;
            controller.popupAdditionalSafeAreaInsets = insets;
        }
    }
    if (layout)
    {
        controller.view.setNeedsUpdateConstraints()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
    }
}
*/

@inline(__always) func PBPopupFixInsetsForViewController(_ controller: UIViewController, _ layout: Bool, _ additionalSafeAreaInsets: UIEdgeInsets)
{
    if (controller is UITabBarController) || (controller is UINavigationController) || (controller.children.count > 0 && !(controller is UISplitViewController))
    {
        let oldInsets = controller.popupAdditionalSafeAreaInsets
        var insets = oldInsets
        if oldInsets.top != additionalSafeAreaInsets.top {
            insets.top += additionalSafeAreaInsets.top
        }
        if oldInsets.bottom != additionalSafeAreaInsets.bottom {
            insets.bottom += additionalSafeAreaInsets.bottom
        }
        if oldInsets != insets {
            controller.popupAdditionalSafeAreaInsets = PBFixInsetsForInsets(insets)
        }
        
        for (_, obj) in controller.children.enumerated() {
            let oldInsets = obj.popupAdditionalSafeAreaInsets
            var insets = oldInsets
            if oldInsets.top != additionalSafeAreaInsets.top {
                insets.top += additionalSafeAreaInsets.top
            }
            if oldInsets.bottom != additionalSafeAreaInsets.bottom {
                insets.bottom += additionalSafeAreaInsets.bottom
            }
            if oldInsets != insets {
                insets = PBFixInsetsForInsets(insets)
                obj.additionalSafeAreaInsets = insets
                obj.popupAdditionalSafeAreaInsets = insets
            }
        }
    } else {
        let oldInsets = controller.popupAdditionalSafeAreaInsets
        var insets = oldInsets
        if oldInsets.top != additionalSafeAreaInsets.top {
            insets.top += additionalSafeAreaInsets.top
        }
        if oldInsets.bottom != additionalSafeAreaInsets.bottom {
            insets.bottom += additionalSafeAreaInsets.bottom
        }
        if oldInsets != insets {
            insets = PBFixInsetsForInsets(insets)
            controller.additionalSafeAreaInsets = insets;
            controller.popupAdditionalSafeAreaInsets = insets;
        }
    }
    if (layout)
    {
        controller.view.setNeedsUpdateConstraints()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
    }
}

@inline(__always) func PBFixInsetsForInsets(_ insets: UIEdgeInsets) -> UIEdgeInsets {
    var insets = insets
    if insets.top < 0 {
        insets.top = 0
    }
    if insets.bottom < 0 {
        insets.bottom = 0
    }
    return insets
}
