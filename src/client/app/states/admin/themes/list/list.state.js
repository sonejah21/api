(function() {
  'use strict';

  angular.module('app.states')
    .run(appRun);

  /** @ngInject */
  function appRun(routerHelper, navigationHelper) {
    routerHelper.configureStates(getStates());
    navigationHelper.navItems(navItems());
    navigationHelper.sidebarItems(sidebarItems());
  }

  function getStates() {
    return {
      'admin.themes.list': {
        url: '', // No url, this state is the index of admin.themes
        templateUrl: 'app/states/admin/themes/list/list.html',
        controller: StateController,
        controllerAs: 'vm',
        title: 'Admin Themes List'
      }
    };
  }

  function navItems() {
    return {};
  }

  function sidebarItems() {
    return {};
  }

  /** @ngInject */
  function resolveThemes(Theme) {
    return Theme.query({latest: 'true', themeable_type: 'Organization'}).$promise;
  }

  /** @ngInject */
  function StateController(lodash, logger, $q, $state, themes, Toasts) {
    var vm = this;

    vm.title = 'Admin Products List';
    vm.themes = themes;

    vm.activate = activate;
    vm.goTo = goTo;
    activate();

    function activate() {
      logger.info('Activated Admin Theme List View');
    }

    function goTo(id) {
      $state.go('admin.themes.create', {themeId: id});
    }

    vm.deleteTheme = deleteTheme;

    function deleteTheme(theme) {
      theme.$delete(deleteSuccess, deleteFailure);

      function deleteSuccess() {
        lodash.remove(vm.themes, {id: theme.id});
        Toasts.toast('Theme deleted.');
      }

      function deleteFailure() {
        Toasts.error('Server returned an error while deleting.');
      }
    }
  }
})();
