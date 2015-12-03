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
      'admin.themes.create': {
        url: '/create/:id',
        templateUrl: 'app/states/admin/themes/create/create.html',
        controller: StateController,
        controllerAs: 'vm',
        title: 'Admin Themes Create',
        resolve: {
          themeRecord: resolveTheme,
          staff: resolveStaff
        }
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
  function resolveTheme($stateParams, Theme) {
    if ($stateParams.id) {
      return Theme.get({id: $stateParams.id}).$promise;
    } else {
      return {};
    }
  }

  /** @ngInject */
  function resolveStaff(Staff) {
    return Staff.getCurrentMember().$promise;
  }

  /** @ngInject */
  function StateController(logger, themeRecord, $stateParams, staff) {
    var vm = this;

    vm.title = 'Admin Themes Create';
    vm.themeRecord = themeRecord;
    vm.activate = activate;
    vm.staffId = staff.id;
    vm.home = 'admin.themes.list';
    vm.homeParams = { };

    // HARD CODED FOR SINGLE TENANT
    vm.themeableType = 'Organization';
    vm.themeableId = '1';

    activate();

    function activate() {
      logger.info('Activated Admin Themes Create View');
    }
  }
})();
