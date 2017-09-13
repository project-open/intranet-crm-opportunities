<div id=@diagram_id@ style="-webkit-user-select: none">

</div>
<script type='text/javascript'>

// Ext.Loader.setConfig({enabled: true});
Ext.Loader.setPath('Ext.ux', '/sencha-v411/examples/ux');
Ext.Loader.setPath('PO.model', '/sencha-core/model');
Ext.Loader.setPath('PO.store', '/sencha-core/store');
Ext.Loader.setPath('PO.class', '/sencha-core/class');
Ext.Loader.setPath('PO.view.gantt', '/sencha-core/view/gantt');
Ext.Loader.setPath('PO.controller', '/sencha-core/controller');

Ext.require([
    'Ext.data.*',
    'Ext.grid.*',
    'Ext.tree.*',
    'PO.store.CategoryStore',
    'PO.store.user.UserStore',
    'PO.store.project.ProjectMainStore'
]);

var projectBaseUrl = "/intranet-crm-opportunities/view?opportunity_id=";

function launchOpportunityPipelineDiagram(){
    // Store of all main projects and project specific fields
    var projectMainStore = Ext.StoreManager.get('projectMainStore');
    var opportunityOwnerStore = Ext.StoreManager.get('opportunityOwnerStore');
    opportunityOwnerStore.insert(0, Ext.create('PO.model.user.User', {
	user_id: "",
	first_names: 'All Opportunities',
	last_name: ''
    }));

    // Store of chart items with chart specific values x_axis, color, etc.
    var chartStore = Ext.create('Ext.data.JsonStore', {
        fields: ['x_axis', 'y_axis', 'color', 'diameter', 'caption', 'project_id', 'project_lead_id'],
        data: []
    });

    // Store for the combo box with users responsible for opportunities
    var pmStore = Ext.create('Ext.data.JsonStore', {
        fields: ['user_id', 'user_name'],
        data: []
    });

    // Write opportunity store values into a static local store in order to
    // work around strange Sencha bug that the combo always reloads the store.
    opportunityOwnerStore.each(function(rec) {
        pmStore.add({
            user_id: rec.get("user_id"),
	    user_name: rec.get("first_names") + " " + rec.get("last_name")
        });
    });
    
    // Transform project values into chart values
    var projectsToChartStore = function() {
	chartStore.removeAll();
	projectMainStore.each(function (rec) {

	    // Only show projects of type "CRM Opportunity"
	    if ("102" != rec.get('project_type_id')) { return true; }
	    
	    var on_track_status = rec.get('on_track_status_id');         // "66"=green, "67"=yellow, "68"=red, ""=undef
            var presales_value = rec.get('presales_value');              // String with number
            var presales_probability = rec.get('presales_probability');  // String with number
            if ("NaN" == presales_value) { presales_value = 0; }
            if ("" == presales_value) { presales_value = 0; }
            if ("NaN" == presales_probability) { presales_probability = 0; }
            if ("" == presales_probability) { presales_probability = 0; }
            presales_value = parseFloat(presales_value);                 // Convert to float number
            presales_probability = parseFloat(presales_probability);

            var color = "white";
            switch (on_track_status) {
            case '66': color = "green"; break;
            case '67': color = "orange"; break;
            case '68': color = "red"; break;
            }
	    
            chartStore.add({
		x_axis: presales_value,
		y_axis: presales_probability,
		color: color,
		diameter: 10,
		caption: rec.get('project_name'),
		project_id: rec.get('project_id'),
		project_lead_id: rec.get('project_lead_id')
            });
	});
    };
    projectsToChartStore();

    var chart = new Ext.chart.Chart({
        width: @diagram_width@,
        height: @diagram_height@,
        animate: true,
        store: chartStore,
	renderTo: '@diagram_id@',
        axes: [{
            type: 'Numeric',
	    title: '@prob_l10n@',
            position: 'left', 
            fields: ['y_axis'], 
            grid: true,
            minimum: 0.0,
	    maximum: 100.0
        }, {
            type: 'Numeric', 
	    title: '@value_l10n@ (@default_currency@)',
            position: 'bottom', 
            fields: ['x_axis'],
            minimum: 0,
	    label: {
		renderer: function(v){
		    if (v > 1000000) { return Math.round(v / 1000000.0)+"M"; }
		    if (v > 1000) { return Math.round(v / 1000.0)+"K"; }
		    return v
		}
	    }
        }],
        series: [{
            type: 'scatter',
            axis: 'left',
            xField: 'x_axis',
            yField: 'y_axis',
            highlight: true,
            markerConfig: { type: 'circle' },

	    label: {
                display: 'under',
                field: 'caption',
                'text-anchor': 'left',
		color: '#000'
            },

            renderer: function(sprite, record, attr, index, store) {
                // Set the properties of every scatter sprite. project_id allows us to trace the 
		// drag-and-drop sprite back to it's original store for updating the entry there.
                var newAttr = Ext.apply(attr, {
                    radius: record.get('diameter'),
                    fill: record.get('color'),
                    project_id: record.get('project_id')
                });
                return newAttr;
            },
            tips: {
                trackMouse: false,
                anchor: 'left',
                width: 300,
                height: 45,
                renderer: function(storeItem, item) {
                    var title = "<a href=\"" + projectBaseUrl + storeItem.get('project_id') + '\">' + 
			storeItem.get('caption') + '</a>' + '<br>' + 
                        '@value_l10n@: ' + parseInt(storeItem.get('x_axis')) + ' @default_currency@, ' + 
                        '@prob_l10n@: ' + parseInt(storeItem.get('y_axis')) + '%';
                    this.setTitle(title);
                }
            }
        }]
    });

/*
    // Main panel with selection
    Ext.create('widget.panel', {
	width: @diagram_width@,
	height: @diagram_height@,
	title: '@diagram_caption@',
	layout: 'fit',
	header: false,
	tbar: [
	    {
		xtype: 'combo',
		editable: false,
		queryMode: 'local',
		mode: 'local',
		store: pmStore,
		autoSelect: false,
		displayField: 'user_name',
		valueField: 'user_id',
		width: 150,
		value: "",
		listeners:{select:{fn:function(combo, comboValues) {
		    var value = comboValues[0].data.user_id;
		    var extraParams = projectMainStore.getProxy().extraParams;
		    delete extraParams.project_lead_id;
    
		    if ("" != value) {
			chartStore.clearFilter();
			chartStore.filter('project_lead_id', ""+value);
		    } else {
			chartStore.clearFilter();
		    }
		    chart.redraw(false);
		}}}
	    }
	],
	items: chart
    });
*/
    
    // Drag - and - Drop variables: The DnD start position and the shape to move
    var dndSpriteShadow = null;
    
    var onSpriteMouseDown = function(sprite, event, eOpts) {
        var offsetX = event.browserEvent.offsetX;
        var offsetY = event.browserEvent.offsetY;
        // console.log("onSpriteMouseDown: "+offsetX+","+offsetY);

        // Create a copy of the sprite without fill
        var attrs = Ext.clone(sprite.attr);
        delete attrs.fill;
        attrs.type = sprite.type;
        attrs.radius = 15;
        attrs.stroke = 'blue';
        attrs['stroke-opacity'] = 1.0;
        dndSpriteShadow = sprite.surface.add(attrs).show(true);
        dndSpriteShadow.dndOrgSprite = sprite;
        dndSpriteShadow.dndStartXY = event.getXY();
    };

    var onSurfaceMouseMove = function(event, eOpts) {
        if (dndSpriteShadow == null) { return; }
        // console.log("onSurfaceMouseMove: "+event.getXY());
        var xy = event.getXY();
        var startXY = dndSpriteShadow.dndStartXY;
        dndSpriteShadow.setAttributes({
            x: xy[0] - startXY[0],
            y: xy[1] - startXY[1]
        }, true);

	var box = this.bgRect.getBox();
        // console.log("onSurfaceMouseMove: x="+box.x+", y="+box.y+", width="+box.width+", height="+box.height);
        console.log("onSurfaceMouseMove: x=" + box.x + ", y=" + box.y + "event_xy: " + xy );

	var xAxis = chart.axes.get('bottom');
        var yAxis = chart.axes.get('left');

        // Relative movement of sprite from original position
        var relX = xy[0] - dndSpriteShadow.dndStartXY[0];
        var relY = xy[1] - dndSpriteShadow.dndStartXY[1];
        relY = -relY;

        // Relative value changed for sprite values
        var relValueX = relX * (xAxis.to - xAxis.from) / xAxis.length;
        var relValueY = relY * (yAxis.to - yAxis.from) / yAxis.length;

	if ( (xy[0] > box.x + @diagram_width@ - 20) && relValueX > 0 ) { 

	    var project_id = dndSpriteShadow.attr.project_id;
	    var rec = projectMainStore.getById(""+project_id);

	    // Evaluate value & probability
	    var presales_value = parseFloat(rec.get('presales_value'));
            var presales_probability = parseFloat(rec.get('presales_probability'));
            if (isNaN(presales_value)) { presales_value = 0; }
            if (isNaN(presales_probability)) { presales_probability = 0; }
            presales_value = Math.round((presales_value + relValueX) / 100.0) * 100;
            presales_probability = Math.round(presales_probability + relValueY);
            if (presales_value < 0.0) { presales_value = 0; }
            if (presales_probability > 100.0) { presales_probability = 100; }
            if (presales_probability < 0.0) { presales_probability = 0; }
	    
	    // console.log("onSurfaceMouseMove: - Entering in RED ZONE - event_xy: " + xy + "project_id: " + project_id + "relValueX: " + relValueX); 

            presales_value = xAxis.to * 2;
            Ext.Msg.alert('Move outside the chart area', "Duplicated value to '" + presales_value+"'.");

	    // Write values back to store
            rec.set('presales_value', "" + presales_value);
            rec.set('presales_probability', ""+presales_probability);
            rec.save();
            // console.log("onSurfaceMouseUp: pid="+project_id+", value="+presales_value+", prob="+presales_probability);

            // Update the record of the chartStore
            var rec = chartStore.getAt(chartStore.find('project_id', ""+project_id));
            rec.set('x_axis', presales_value);
            rec.set('y_axis', presales_probability);

            // Close the DnD operation
            this.remove(dndSpriteShadow, true);
            dndSpriteShadow = null;
            dndStart = null;
	}

    };

    var onSurfaceMouseUp = function(event, eOpts) {
        var surface = chart.surface;
        var xy = event.getXY();
        if (dndSpriteShadow == null) { return; }

        // Event coordinates relative to surface (why?)
        var offsetX = event.browserEvent.offsetX;
        var offsetY = event.browserEvent.offsetY;

        // Get the axis of the chart
        var xAxis = chart.axes.get('bottom');
        var yAxis = chart.axes.get('left');

        // Relative movement of sprite from original position
        var relX = xy[0] - dndSpriteShadow.dndStartXY[0];
        var relY = xy[1] - dndSpriteShadow.dndStartXY[1];
        relY = -relY;

        // Relative value changed for sprite values
        var relValueX = relX * (xAxis.to - xAxis.from) / xAxis.length;
        var relValueY = relY * (yAxis.to - yAxis.from) / yAxis.length;
        // console.log("onSurfaceMouseUp: pid="+project_id+", relXY=("+relX+","+relY+"), val=("+relValueX+","+relValueY+")");

        // Write updated values into server store
        var project_id = dndSpriteShadow.attr.project_id;
        var rec = projectMainStore.getById(""+project_id);
        var presales_value = parseFloat(rec.get('presales_value'));
        var presales_probability = parseFloat(rec.get('presales_probability'));
        if (isNaN(presales_value)) { presales_value = 0; }
        if (isNaN(presales_probability)) { presales_probability = 0; }
        presales_value = Math.round((presales_value + relValueX) / 100.0) * 100;
        presales_probability = Math.round(presales_probability + relValueY);
        if (presales_value < 0.0) { presales_value = 0; }
        if (presales_probability > 100.0) { presales_probability = 100; }
        if (presales_probability < 0.0) { presales_probability = 0; }

	// Check if we have left the chart.
	// In this case we start the out-of-chart logic
	// if (presales_value > xAxis.to) {
	//    presales_value = xAxis.to * 2;
	//    Ext.Msg.alert('Move outside the chart area', "Duplicated value to '" + presales_value+"'.");
	// }
	
	// Write values back to store
	rec.set('presales_value', ""+presales_value);
        rec.set('presales_probability', ""+presales_probability);
        rec.save();
        // console.log("onSurfaceMouseUp: pid="+project_id+", value="+presales_value+", prob="+presales_probability);

        // Update the record of the chartStore
        var rec = chartStore.getAt(chartStore.find('project_id', ""+project_id));
        rec.set('x_axis', presales_value);
        rec.set('y_axis', presales_probability);

        // Close the DnD operation
        this.remove(dndSpriteShadow, true);
        dndSpriteShadow = null;
        dndStart = null;
    };

    // KH: 170531: Not used
    // var onRightBorderSpriteMouseOver = function(sprite, event) {
    //    if (dndSpriteShadow == null) { return; }
    //    console.log("onRightBorderSpriteMouseOver: "+event.getXY());
    // };

    // Add drag-and-drop listeners to the sprites
    var surface = chart.surface;
    var items = surface.items.items;
    for (var i = 0, ln = items.length; i < ln; i++) {
	var sprite = items[i];
	if (sprite.type != "circle") { continue; } // only add listeners to circles
        sprite.on("mousedown", onSpriteMouseDown, sprite);
    }
    surface.on("mousemove", onSurfaceMouseMove, surface);
    surface.on("mouseup", onSurfaceMouseUp, surface);
};

Ext.onReady(function() {
    Ext.QuickTips.init();

    var projectMainStore = Ext.create('PO.store.project.ProjectMainStore');
    var opportunityOwnerStore = Ext.create('PO.store.user.UserStore', {
	storeId: 'opportunityOwnerStore',
    });

    // Use a "store coodinator" in order to launchTreePanel() after all stores have been loaded
    var coordinator = Ext.create('PO.controller.StoreLoadCoordinator', {
        stores: [
            'projectMainStore',
	    'opportunityOwnerStore'
        ],
        listeners: {
            load: function() {
                // Check if the application was launched before
                if ("boolean" == typeof this.loadedP) { return; }
                // Launch the actual application.
                launchOpportunityPipelineDiagram();
                // Mark the application as launched
                this.loadedP = true;
            }
        }
    });

    // Load stores that need parameters
    projectMainStore.getProxy().extraParams = { 
	format: "json",
	query: "parent_id is null and project_type_id = 102"
    };
    projectMainStore.load();

    // Load the list of Opportunity owners
    opportunityOwnerStore.getProxy().extraParams = {
	format: "json",
	query: "user_id in (select project_lead_id from im_projects where parent_id is null and project_type_id = 102)"
    };

    opportunityOwnerStore.load();

});
</script>
</div>
